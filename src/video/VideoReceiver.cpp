#include "VideoReceiver.h"
#include <QDebug>
#include <QDateTime>
#include <QUrl>

#ifdef HAS_GSTREAMER
#include <gst/video/video.h>
#endif

VideoReceiver::VideoReceiver(QObject *parent)
    : QObject(parent)
{
#ifdef HAS_GSTREAMER
    // GStreamer is initialized once globally in main or VideoManager
#endif
}

VideoReceiver::~VideoReceiver()
{
    stop();
}

void VideoReceiver::setUri(const QString &uri)
{
    if (m_uri != uri) {
        bool wasPlaying = m_playing;
        if (wasPlaying) stop();
        m_uri = uri;
        emit uriChanged();
        if (wasPlaying) start();
    }
}

void VideoReceiver::setVideoSink(QVideoSink *sink)
{
    m_videoSink = sink;
}

void VideoReceiver::start()
{
    if (m_uri.isEmpty()) {
        setStatus("No URI configured");
        return;
    }

#ifdef HAS_GSTREAMER
    createPipeline();
#else
    setStatus("GStreamer not available");
    qWarning() << "VideoReceiver: GStreamer not available, cannot start" << m_uri;
#endif
}

void VideoReceiver::stop()
{
#ifdef HAS_GSTREAMER
    destroyPipeline();
#endif
    setPlaying(false);
    setStatus("Stopped");
}

void VideoReceiver::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
    }
}

void VideoReceiver::setPlaying(bool playing)
{
    if (m_playing != playing) {
        m_playing = playing;
        emit playingChanged();
    }
}

#ifdef HAS_GSTREAMER

void VideoReceiver::createPipeline()
{
    destroyPipeline();

    setStatus("Connecting...");

    // Build pipeline string based on URI scheme
    QString pipelineStr;
    QString uri = m_uri.trimmed();

    qDebug() << "VideoReceiver: Creating pipeline for URI:" << uri;

    if (uri.startsWith("rtsp://")) {
        pipelineStr = QString(
            "rtspsrc location=%1 latency=200 ! "
            "rtph264depay ! h264parse ! "
            "avdec_h264 ! "
            "videoconvert ! video/x-raw,format=RGBA ! "
            "appsink name=qtsink emit-signals=true max-buffers=2 drop=true"
        ).arg(uri);
    } else if (uri.startsWith("udp://") || uri.startsWith("udp:")) {
        // UDP H.264 stream (e.g., from BlueOS / RPi camera)
        // Format: udp://HOST:PORT or udp://0.0.0.0:PORT
        // We extract the port and listen with udpsrc

        // Parse port from URI: find last ':' after the host
        int port = 5600;
        QString cleaned = uri;
        cleaned.remove("udp://").remove("udp:");
        int colonIdx = cleaned.lastIndexOf(':');
        if (colonIdx >= 0) {
            bool ok;
            int p = cleaned.mid(colonIdx + 1).toInt(&ok);
            if (ok && p > 0) port = p;
        }

        qDebug() << "VideoReceiver: UDP H.264/RTP pipeline on port" << port;

        // udpsrc listens on the port for incoming RTP H.264 packets
        pipelineStr = QString(
            "udpsrc port=%1 "
            "buffer-size=524288 "
            "caps=\"application/x-rtp,media=video,encoding-name=H264,payload=96\" ! "
            "rtpjitterbuffer latency=100 ! "
            "rtph264depay ! h264parse ! "
            "avdec_h264 ! "
            "videoconvert ! video/x-raw,format=RGBA ! "
            "appsink name=qtsink emit-signals=true max-buffers=2 drop=true"
        ).arg(port);
    } else if (uri.startsWith("test://")) {
        // Test pattern for development
        pipelineStr = QString(
            "videotestsrc pattern=0 ! "
            "video/x-raw,width=640,height=480,framerate=30/1 ! "
            "videoconvert ! video/x-raw,format=RGBA ! "
            "appsink name=qtsink emit-signals=true max-buffers=2 drop=true"
        );
    } else {
        setStatus("Unsupported URI: " + uri);
        qWarning() << "VideoReceiver: Unsupported URI scheme:" << uri
                    << "(supported: rtsp://, udp://, test://)";
        return;
    }

    qDebug() << "VideoReceiver: Pipeline:" << pipelineStr;

    GError *error = nullptr;
    m_pipeline = gst_parse_launch(pipelineStr.toUtf8().constData(), &error);

    if (error) {
        setStatus(QString("Pipeline error: %1").arg(error->message));
        g_error_free(error);
        return;
    }

    m_appsink = gst_bin_get_by_name(GST_BIN(m_pipeline), "qtsink");
    if (!m_appsink) {
        setStatus("Failed to get appsink");
        destroyPipeline();
        return;
    }

    // Configure appsink callbacks
    GstAppSinkCallbacks callbacks = {};
    callbacks.new_sample = onNewSample;
    gst_app_sink_set_callbacks(GST_APP_SINK(m_appsink), &callbacks, this, nullptr);

    // Start playing
    GstStateChangeReturn ret = gst_element_set_state(m_pipeline, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        setStatus("Failed to start pipeline");
        destroyPipeline();
        return;
    }

    setPlaying(true);
    setStatus("Playing");
    m_lastFpsUpdate = QDateTime::currentMSecsSinceEpoch();
    m_frameCount = 0;
}

void VideoReceiver::destroyPipeline()
{
    if (m_pipeline) {
        gst_element_set_state(m_pipeline, GST_STATE_NULL);

        if (m_appsink) {
            gst_object_unref(m_appsink);
            m_appsink = nullptr;
        }

        gst_object_unref(m_pipeline);
        m_pipeline = nullptr;
    }
}

GstFlowReturn VideoReceiver::onNewSample(GstAppSink *sink, gpointer userData)
{
    auto *self = static_cast<VideoReceiver*>(userData);

    GstSample *sample = gst_app_sink_pull_sample(sink);
    if (!sample) return GST_FLOW_ERROR;

    GstBuffer *buffer = gst_sample_get_buffer(sample);
    GstCaps *caps = gst_sample_get_caps(sample);

    if (buffer && caps) {
        GstVideoInfo info;
        if (gst_video_info_from_caps(&info, caps)) {
            int width = GST_VIDEO_INFO_WIDTH(&info);
            int height = GST_VIDEO_INFO_HEIGHT(&info);

            if (width != self->m_width || height != self->m_height) {
                self->m_width = width;
                self->m_height = height;
                QMetaObject::invokeMethod(self, "resolutionChanged", Qt::QueuedConnection);
            }

            GstMapInfo mapInfo;
            if (gst_buffer_map(buffer, &mapInfo, GST_MAP_READ)) {
                // Create QVideoFrame from RGBA data
                QVideoFrameFormat format(QSize(width, height), QVideoFrameFormat::Format_RGBA8888);
                QVideoFrame frame(format);

                if (frame.map(QVideoFrame::WriteOnly)) {
                    memcpy(frame.bits(0), mapInfo.data, qMin((gsize)frame.mappedBytes(0), mapInfo.size));
                    frame.unmap();

                    if (self->m_videoSink) {
                        self->m_videoSink->setVideoFrame(frame);
                    }
                }

                gst_buffer_unmap(buffer, &mapInfo);

                // FPS tracking
                self->m_frameCount++;
                qint64 now = QDateTime::currentMSecsSinceEpoch();
                if (now - self->m_lastFpsUpdate >= 1000) {
                    self->m_fps = self->m_frameCount;
                    self->m_frameCount = 0;
                    self->m_lastFpsUpdate = now;
                    QMetaObject::invokeMethod(self, "fpsChanged", Qt::QueuedConnection);
                }
            }
        }
    }

    gst_sample_unref(sample);
    return GST_FLOW_OK;
}

#endif // HAS_GSTREAMER

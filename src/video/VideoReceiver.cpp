#include "VideoReceiver.h"
#include <QDebug>
#include <QDateTime>

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

    if (m_uri.startsWith("rtsp://")) {
        pipelineStr = QString(
            "rtspsrc location=%1 latency=200 ! "
            "rtph264depay ! h264parse ! "
            "avdec_h264 ! "
            "videoconvert ! video/x-raw,format=RGBA ! "
            "appsink name=qtsink emit-signals=true max-buffers=2 drop=true"
        ).arg(m_uri);
    } else if (m_uri.startsWith("udp://")) {
        // UDP H.264 stream (e.g., from RPi camera)
        QString host = m_uri.mid(6);
        pipelineStr = QString(
            "udpsrc uri=%1 ! "
            "application/x-rtp,encoding-name=H264 ! "
            "rtph264depay ! h264parse ! "
            "avdec_h264 ! "
            "videoconvert ! video/x-raw,format=RGBA ! "
            "appsink name=qtsink emit-signals=true max-buffers=2 drop=true"
        ).arg(m_uri);
    } else if (m_uri.startsWith("test://")) {
        // Test pattern for development
        pipelineStr = QString(
            "videotestsrc pattern=0 ! "
            "video/x-raw,width=640,height=480,framerate=30/1 ! "
            "videoconvert ! video/x-raw,format=RGBA ! "
            "appsink name=qtsink emit-signals=true max-buffers=2 drop=true"
        );
    } else {
        // File or other source
        pipelineStr = QString(
            "uridecodebin uri=%1 ! "
            "videoconvert ! video/x-raw,format=RGBA ! "
            "appsink name=qtsink emit-signals=true max-buffers=2 drop=true"
        ).arg(m_uri);
    }

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

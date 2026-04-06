#pragma once

#include <QObject>
#include <QString>
#include <QVideoFrame>
#include <QVideoSink>

#ifdef HAS_GSTREAMER
#include <gst/gst.h>
#include <gst/app/gstappsink.h>
#endif

class VideoReceiver : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString uri READ uri WRITE setUri NOTIFY uriChanged)
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(int width READ width NOTIFY resolutionChanged)
    Q_PROPERTY(int height READ height NOTIFY resolutionChanged)
    Q_PROPERTY(int fps READ fps NOTIFY fpsChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit VideoReceiver(QObject *parent = nullptr);
    ~VideoReceiver();

    QString uri() const { return m_uri; }
    Q_INVOKABLE void setUri(const QString &uri);

    bool isPlaying() const { return m_playing; }
    int width() const { return m_width; }
    int height() const { return m_height; }
    int fps() const { return m_fps; }
    QString status() const { return m_status; }

    Q_INVOKABLE void setVideoSink(QVideoSink *sink);

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

signals:
    void uriChanged();
    void playingChanged();
    void resolutionChanged();
    void fpsChanged();
    void statusChanged();
    void newFrame(const QVideoFrame &frame);

private:
    void setStatus(const QString &status);
    void setPlaying(bool playing);

#ifdef HAS_GSTREAMER
    void createPipeline();
    void destroyPipeline();
    static GstFlowReturn onNewSample(GstAppSink *sink, gpointer userData);

    GstElement *m_pipeline = nullptr;
    GstElement *m_appsink = nullptr;
#endif

    QString m_uri;
    bool m_playing = false;
    int m_width = 0;
    int m_height = 0;
    int m_fps = 0;
    QString m_status = "Idle";
    QVideoSink *m_videoSink = nullptr;

    // FPS tracking
    int m_frameCount = 0;
    qint64 m_lastFpsUpdate = 0;
};

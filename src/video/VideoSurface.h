#pragma once

#include <QQuickItem>
#include <QVideoSink>

class VideoReceiver;

class VideoSurface : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(int streamIndex READ streamIndex WRITE setStreamIndex NOTIFY streamIndexChanged)
    Q_PROPERTY(QVideoSink* videoSink READ videoSink WRITE setVideoSink NOTIFY videoSinkChanged)

public:
    explicit VideoSurface(QQuickItem *parent = nullptr);

    int streamIndex() const { return m_streamIndex; }
    void setStreamIndex(int index);

    QVideoSink* videoSink() const { return m_videoSink; }
    void setVideoSink(QVideoSink *sink);

signals:
    void streamIndexChanged();
    void videoSinkChanged();

private:
    int m_streamIndex = 0;
    QVideoSink *m_videoSink = nullptr;
};

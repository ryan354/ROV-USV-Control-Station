#include "VideoSurface.h"
#include "VideoReceiver.h"
#include "VideoManager.h"
#include <QQmlEngine>
#include <QQmlContext>

VideoSurface::VideoSurface(QQuickItem *parent)
    : QQuickItem(parent)
{
}

void VideoSurface::setStreamIndex(int index)
{
    if (m_streamIndex != index) {
        m_streamIndex = index;
        emit streamIndexChanged();
    }
}

void VideoSurface::setVideoSink(QVideoSink *sink)
{
    if (m_videoSink != sink) {
        m_videoSink = sink;

        // Connect the video sink to the corresponding VideoReceiver
        auto *context = QQmlEngine::contextForObject(this);
        if (context) {
            auto *vm = qobject_cast<VideoManager*>(context->contextProperty("videoManager").value<QObject*>());
            if (vm) {
                auto *receiver = vm->receiver(m_streamIndex);
                if (receiver) {
                    receiver->setVideoSink(sink);
                }
            }
        }

        emit videoSinkChanged();
    }
}

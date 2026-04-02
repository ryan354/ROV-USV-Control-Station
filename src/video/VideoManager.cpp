#include "VideoManager.h"
#include "VideoReceiver.h"
#include <QDebug>

#ifdef HAS_GSTREAMER
#include <gst/gst.h>
#endif

VideoManager::VideoManager(QObject *parent)
    : QObject(parent)
{
#ifdef HAS_GSTREAMER
    // Initialize GStreamer once
    if (!gst_is_initialized()) {
        gst_init(nullptr, nullptr);
        qDebug() << "VideoManager: GStreamer initialized, version:" << gst_version_string();
    }
#else
    qDebug() << "VideoManager: GStreamer not available";
#endif

    // Create receivers for all stream slots
    for (int i = 0; i < MAX_STREAMS; ++i) {
        auto *receiver = new VideoReceiver(this);
        m_receivers.append(receiver);
    }
}

VideoManager::~VideoManager()
{
    stopAll();
}

VideoReceiver* VideoManager::receiver(int index) const
{
    if (index >= 0 && index < m_receivers.size()) {
        return m_receivers.at(index);
    }
    return nullptr;
}

void VideoManager::setStreamUri(int index, const QString &uri)
{
    if (auto *r = receiver(index)) {
        r->setUri(uri);
    }
}

void VideoManager::startStream(int index)
{
    if (auto *r = receiver(index)) {
        r->start();
    }
}

void VideoManager::stopStream(int index)
{
    if (auto *r = receiver(index)) {
        r->stop();
    }
}

void VideoManager::startAll()
{
    for (auto *r : m_receivers) {
        if (!r->uri().isEmpty()) {
            r->start();
        }
    }
}

void VideoManager::stopAll()
{
    for (auto *r : m_receivers) {
        r->stop();
    }
}

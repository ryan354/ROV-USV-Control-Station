#pragma once

#include <QObject>
#include <QList>

class VideoReceiver;

class VideoManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int streamCount READ streamCount CONSTANT)

public:
    explicit VideoManager(QObject *parent = nullptr);
    ~VideoManager();

    int streamCount() const { return m_receivers.size(); }

    Q_INVOKABLE VideoReceiver* receiver(int index) const;
    Q_INVOKABLE void setStreamUri(int index, const QString &uri);
    Q_INVOKABLE void startStream(int index);
    Q_INVOKABLE void stopStream(int index);
    Q_INVOKABLE void startAll();
    Q_INVOKABLE void stopAll();

    static constexpr int MAX_STREAMS = 4;

private:
    QList<VideoReceiver*> m_receivers;
};

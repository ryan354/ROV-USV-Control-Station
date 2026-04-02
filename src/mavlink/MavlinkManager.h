#pragma once

#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include <QHostAddress>
#include <QList>

// MAVLink C headers
#define MAVLINK_USE_MESSAGE_INFO
#include "ardupilotmega/mavlink.h"

class MavlinkManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool listening READ isListening NOTIFY listeningChanged)
    Q_PROPERTY(QString ports READ portsString NOTIFY portsChanged)
    Q_PROPERTY(int messagesPerSecond READ messagesPerSecond NOTIFY statsUpdated)

public:
    explicit MavlinkManager(QObject *parent = nullptr);
    ~MavlinkManager();

    bool isListening() const { return m_listening; }
    QString portsString() const;
    int messagesPerSecond() const { return m_messagesPerSecond; }

    // Start listening on one or two ports
    Q_INVOKABLE void start(int rovPort, int usvPort = 0);
    Q_INVOKABLE void stop();

    // Send to the last known address for a given sysid
    void sendToVehicle(const mavlink_message_t &msg, uint8_t targetSysId);

signals:
    void messageReceived(const mavlink_message_t &msg, const QHostAddress &senderAddress, quint16 senderPort);
    void listeningChanged();
    void portsChanged();
    void statsUpdated();

private slots:
    void readPendingDatagrams();
    void sendHeartbeat();
    void updateStats();

private:
    void sendMessage(const mavlink_message_t &msg, const QHostAddress &address, quint16 port);

    QList<QUdpSocket*> m_sockets;
    QTimer m_heartbeatTimer;
    QTimer m_statsTimer;

    bool m_listening = false;
    QList<int> m_ports;

    // Message rate tracking
    int m_messageCount = 0;
    int m_messagesPerSecond = 0;

    // Track vehicle endpoints for reply routing
    struct VehicleEndpoint {
        QHostAddress address;
        quint16 port;
    };
    QMap<uint8_t, VehicleEndpoint> m_vehicleEndpoints;

    // GCS identifiers
    static constexpr uint8_t GCS_SYSID = 255;
    static constexpr uint8_t GCS_COMPID = 190;
};

#include "MavlinkManager.h"
#include <QNetworkDatagram>
#include <QDebug>

MavlinkManager::MavlinkManager(QObject *parent)
    : QObject(parent)
{
    // Send GCS heartbeat at 1 Hz
    connect(&m_heartbeatTimer, &QTimer::timeout, this, &MavlinkManager::sendHeartbeat);
    // Update stats every second
    connect(&m_statsTimer, &QTimer::timeout, this, &MavlinkManager::updateStats);
}

MavlinkManager::~MavlinkManager()
{
    stop();
}

QString MavlinkManager::portsString() const
{
    QStringList parts;
    for (int p : m_ports) parts << QString::number(p);
    return parts.join(", ");
}

void MavlinkManager::start(int rovPort, int usvPort)
{
    stop();

    // Collect unique ports
    QList<int> ports;
    ports << rovPort;
    if (usvPort > 0 && usvPort != rovPort) {
        ports << usvPort;
    }

    for (int port : ports) {
        auto *socket = new QUdpSocket(this);
        if (socket->bind(QHostAddress::AnyIPv4, port,
                         QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
            connect(socket, &QUdpSocket::readyRead, this, &MavlinkManager::readPendingDatagrams);
            m_sockets.append(socket);
            m_ports.append(port);
            qDebug() << "MavlinkManager: Listening on port" << port;
        } else {
            qWarning() << "MavlinkManager: Failed to bind port" << port << socket->errorString();
            delete socket;
        }
    }

    if (!m_sockets.isEmpty()) {
        m_listening = true;
        m_heartbeatTimer.start(1000);
        m_statsTimer.start(1000);
        emit listeningChanged();
        emit portsChanged();
    }
}

void MavlinkManager::stop()
{
    m_heartbeatTimer.stop();
    m_statsTimer.stop();

    for (auto *socket : m_sockets) {
        socket->close();
        delete socket;
    }
    m_sockets.clear();
    m_ports.clear();
    m_vehicleEndpoints.clear();

    if (m_listening) {
        m_listening = false;
        emit listeningChanged();
        emit portsChanged();
    }
}

void MavlinkManager::readPendingDatagrams()
{
    auto *socket = qobject_cast<QUdpSocket*>(sender());
    if (!socket) return;

    while (socket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = socket->receiveDatagram();
        QByteArray data = datagram.data();
        QHostAddress senderAddress = datagram.senderAddress();
        quint16 senderPort = datagram.senderPort();

        mavlink_message_t msg;
        mavlink_status_t status;

        for (int i = 0; i < data.size(); ++i) {
            uint8_t byte = static_cast<uint8_t>(data.at(i));
            if (mavlink_parse_char(MAVLINK_COMM_0, byte, &msg, &status)) {
                m_messageCount++;

                // Track vehicle endpoint for reply routing
                if (msg.sysid != GCS_SYSID) {
                    m_vehicleEndpoints[msg.sysid] = {senderAddress, senderPort};
                }

                emit messageReceived(msg, senderAddress, senderPort);
            }
        }
    }
}

void MavlinkManager::sendHeartbeat()
{
    mavlink_message_t msg;
    mavlink_msg_heartbeat_pack(
        GCS_SYSID, GCS_COMPID, &msg,
        MAV_TYPE_GCS, MAV_AUTOPILOT_INVALID,
        0, 0, MAV_STATE_ACTIVE
    );

    // Send heartbeat to all known vehicle endpoints
    for (auto it = m_vehicleEndpoints.constBegin(); it != m_vehicleEndpoints.constEnd(); ++it) {
        sendMessage(msg, it.value().address, it.value().port);
    }

    // If no vehicles known, broadcast on all listening ports
    if (m_vehicleEndpoints.isEmpty()) {
        QByteArray buf(MAVLINK_MAX_PACKET_LEN, 0);
        int len = mavlink_msg_to_send_buffer(reinterpret_cast<uint8_t*>(buf.data()), &msg);
        buf.resize(len);
        for (auto *socket : m_sockets) {
            socket->writeDatagram(buf, QHostAddress::Broadcast, socket->localPort());
        }
    }
}

void MavlinkManager::sendMessage(const mavlink_message_t &msg, const QHostAddress &address, quint16 port)
{
    QByteArray buf(MAVLINK_MAX_PACKET_LEN, 0);
    int len = mavlink_msg_to_send_buffer(reinterpret_cast<uint8_t*>(buf.data()), &msg);
    buf.resize(len);

    // Send via the first available socket
    if (!m_sockets.isEmpty()) {
        m_sockets.first()->writeDatagram(buf, address, port);
    }
}

void MavlinkManager::sendToVehicle(const mavlink_message_t &msg, uint8_t targetSysId)
{
    auto it = m_vehicleEndpoints.find(targetSysId);
    if (it != m_vehicleEndpoints.end()) {
        sendMessage(msg, it.value().address, it.value().port);
    } else {
        qWarning() << "MavlinkManager: No endpoint for sysid" << targetSysId;
    }
}

void MavlinkManager::updateStats()
{
    m_messagesPerSecond = m_messageCount;
    m_messageCount = 0;
    emit statsUpdated();
}

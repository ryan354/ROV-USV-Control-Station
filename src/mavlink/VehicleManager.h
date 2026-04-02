#pragma once

#include <QObject>
#include <QMap>
#include <QList>
#include <QHostAddress>

#include "ardupilotmega/mavlink.h"

class Vehicle;
class MavlinkManager;

class VehicleManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(Vehicle* activeVehicle READ activeVehicle WRITE setActiveVehicle NOTIFY activeVehicleChanged)
    Q_PROPERTY(Vehicle* rovVehicle READ rovVehicle NOTIFY vehiclesChanged)
    Q_PROPERTY(Vehicle* usvVehicle READ usvVehicle NOTIFY vehiclesChanged)
    Q_PROPERTY(int vehicleCount READ vehicleCount NOTIFY vehiclesChanged)
    Q_PROPERTY(QList<Vehicle*> vehicles READ vehicles NOTIFY vehiclesChanged)

public:
    explicit VehicleManager(MavlinkManager *mavlink, QObject *parent = nullptr);

    Vehicle* activeVehicle() const { return m_activeVehicle; }
    void setActiveVehicle(Vehicle *vehicle);

    Vehicle* rovVehicle() const;
    Vehicle* usvVehicle() const;
    Vehicle* vehicleBySysId(uint8_t sysId) const;

    int vehicleCount() const { return m_vehicles.size(); }
    QList<Vehicle*> vehicles() const { return m_vehicles.values(); }

    Q_INVOKABLE void selectROV();
    Q_INVOKABLE void selectUSV();
    Q_INVOKABLE void selectVehicle(int sysId);

public slots:
    void handleMavlinkMessage(const mavlink_message_t &msg, const QHostAddress &senderAddress, quint16 senderPort);

signals:
    void activeVehicleChanged();
    void vehiclesChanged();
    void vehicleAdded(Vehicle *vehicle);
    void vehicleRemoved(Vehicle *vehicle);
    void vehiclePositionChanged(int sysId, double latitude, double longitude, double heading, int vehicleType);

private:
    MavlinkManager *m_mavlink;
    QMap<uint8_t, Vehicle*> m_vehicles;
    Vehicle *m_activeVehicle = nullptr;
};

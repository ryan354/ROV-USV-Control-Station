#include "VehicleManager.h"
#include "Vehicle.h"
#include "MavlinkManager.h"
#include <QDebug>

VehicleManager::VehicleManager(MavlinkManager *mavlink, QObject *parent)
    : QObject(parent)
    , m_mavlink(mavlink)
{
}

void VehicleManager::setActiveVehicle(Vehicle *vehicle)
{
    if (m_activeVehicle != vehicle) {
        m_activeVehicle = vehicle;
        emit activeVehicleChanged();
    }
}

Vehicle* VehicleManager::rovVehicle() const
{
    for (auto *v : m_vehicles) {
        if (v->vehicleType() == Vehicle::ROV) return v;
    }
    return nullptr;
}

Vehicle* VehicleManager::usvVehicle() const
{
    for (auto *v : m_vehicles) {
        if (v->vehicleType() == Vehicle::USV) return v;
    }
    return nullptr;
}

Vehicle* VehicleManager::vehicleBySysId(uint8_t sysId) const
{
    return m_vehicles.value(sysId, nullptr);
}

void VehicleManager::selectROV()
{
    Vehicle *rov = rovVehicle();
    if (rov) setActiveVehicle(rov);
}

void VehicleManager::selectUSV()
{
    Vehicle *usv = usvVehicle();
    if (usv) setActiveVehicle(usv);
}

void VehicleManager::selectVehicle(int sysId)
{
    Vehicle *v = vehicleBySysId(static_cast<uint8_t>(sysId));
    if (v) setActiveVehicle(v);
}

void VehicleManager::handleMavlinkMessage(const mavlink_message_t &msg,
                                            const QHostAddress &senderAddress,
                                            quint16 senderPort)
{
    Q_UNUSED(senderAddress)
    Q_UNUSED(senderPort)

    uint8_t sysId = msg.sysid;

    // Skip GCS messages
    if (sysId == 255) return;

    // Create vehicle on first heartbeat
    if (msg.msgid == MAVLINK_MSG_ID_HEARTBEAT) {
        mavlink_heartbeat_t hb;
        mavlink_msg_heartbeat_decode(&msg, &hb);

        // Skip non-vehicle components (GCS, ADSB, etc.)
        if (hb.type == MAV_TYPE_GCS || hb.type == MAV_TYPE_ADSB) return;

        if (!m_vehicles.contains(sysId)) {
            auto *vehicle = new Vehicle(sysId, m_mavlink, this);
            m_vehicles.insert(sysId, vehicle);

            // When vehicle type is identified (ROV/USV), re-notify QML
            // so rovVehicle/usvVehicle properties update
            connect(vehicle, &Vehicle::vehicleTypeChanged, this, &VehicleManager::vehiclesChanged);
            connect(vehicle, &Vehicle::connectedChanged, this, &VehicleManager::vehiclesChanged);

            // Forward position changes to map
            connect(vehicle, &Vehicle::positionChanged, this, [this, vehicle]() {
                emit vehiclePositionChanged(
                    vehicle->sysId(),
                    vehicle->latitude(),
                    vehicle->longitude(),
                    vehicle->heading(),
                    static_cast<int>(vehicle->vehicleType())
                );
            });

            qDebug() << "VehicleManager: New vehicle detected sysid=" << sysId;
            emit vehicleAdded(vehicle);
            emit vehiclesChanged();

            // Set as active if no active vehicle
            if (!m_activeVehicle) {
                setActiveVehicle(vehicle);
            }
        }
    }

    // Route message to vehicle
    Vehicle *vehicle = m_vehicles.value(sysId, nullptr);
    if (vehicle) {
        vehicle->handleMessage(msg);
    }
}

#pragma once

#include <QObject>
#include <QTimer>
#include <QElapsedTimer>
#include <QHostAddress>

#include "ardupilotmega/mavlink.h"

class MavlinkManager;

class Vehicle : public QObject
{
    Q_OBJECT

    // ─── Identity ───────────────────────────────────────────────────────────
    Q_PROPERTY(int sysId READ sysId CONSTANT)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(VehicleType vehicleType READ vehicleType NOTIFY vehicleTypeChanged)
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)

    // ─── Attitude ───────────────────────────────────────────────────────────
    Q_PROPERTY(double roll READ roll NOTIFY attitudeChanged)
    Q_PROPERTY(double pitch READ pitch NOTIFY attitudeChanged)
    Q_PROPERTY(double yaw READ yaw NOTIFY attitudeChanged)
    Q_PROPERTY(double heading READ heading NOTIFY attitudeChanged)

    // ─── Position ───────────────────────────────────────────────────────────
    Q_PROPERTY(double latitude READ latitude NOTIFY positionChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY positionChanged)
    Q_PROPERTY(double altitude READ altitude NOTIFY positionChanged)
    Q_PROPERTY(double depth READ depth NOTIFY positionChanged)

    // ─── Navigation ─────────────────────────────────────────────────────────
    Q_PROPERTY(double groundSpeed READ groundSpeed NOTIFY navigationChanged)
    Q_PROPERTY(double climbRate READ climbRate NOTIFY navigationChanged)
    Q_PROPERTY(double throttle READ throttle NOTIFY navigationChanged)

    // ─── Battery ────────────────────────────────────────────────────────────
    Q_PROPERTY(double batteryVoltage READ batteryVoltage NOTIFY batteryChanged)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY batteryChanged)
    Q_PROPERTY(double batteryCurrent READ batteryCurrent NOTIFY batteryChanged)

    // ─── GPS ────────────────────────────────────────────────────────────────
    Q_PROPERTY(int gpsFixType READ gpsFixType NOTIFY gpsChanged)
    Q_PROPERTY(int gpsSatCount READ gpsSatCount NOTIFY gpsChanged)
    Q_PROPERTY(int gpsHdop READ gpsHdop NOTIFY gpsChanged)

    // ─── State ──────────────────────────────────────────────────────────────
    Q_PROPERTY(bool armed READ isArmed NOTIFY armedChanged)
    Q_PROPERTY(QString flightMode READ flightMode NOTIFY flightModeChanged)
    Q_PROPERTY(int baseMode READ baseMode NOTIFY baseModeChanged)
    Q_PROPERTY(int customMode READ customMode NOTIFY flightModeChanged)

public:
    enum VehicleType {
        Unknown = 0,
        ROV,
        USV
    };
    Q_ENUM(VehicleType)

    explicit Vehicle(uint8_t sysId, MavlinkManager *mavlink, QObject *parent = nullptr);

    // Identity
    int sysId() const { return m_sysId; }
    QString name() const { return m_name; }
    VehicleType vehicleType() const { return m_vehicleType; }
    bool isConnected() const { return m_connected; }

    // Attitude (degrees)
    double roll() const { return m_roll; }
    double pitch() const { return m_pitch; }
    double yaw() const { return m_yaw; }
    double heading() const { return m_yaw < 0 ? m_yaw + 360.0 : m_yaw; }

    // Position
    double latitude() const { return m_latitude; }
    double longitude() const { return m_longitude; }
    double altitude() const { return m_altitude; }
    double depth() const { return m_depth; }

    // Navigation
    double groundSpeed() const { return m_groundSpeed; }
    double climbRate() const { return m_climbRate; }
    double throttle() const { return m_throttle; }

    // Battery
    double batteryVoltage() const { return m_batteryVoltage; }
    int batteryPercent() const { return m_batteryPercent; }
    double batteryCurrent() const { return m_batteryCurrent; }

    // GPS
    int gpsFixType() const { return m_gpsFixType; }
    int gpsSatCount() const { return m_gpsSatCount; }
    int gpsHdop() const { return m_gpsHdop; }

    // State
    bool isArmed() const { return m_armed; }
    QString flightMode() const { return m_flightMode; }
    int baseMode() const { return m_baseMode; }
    int customMode() const { return m_customMode; }

    // Process incoming MAVLink message
    void handleMessage(const mavlink_message_t &msg);

    // ─── Commands ───────────────────────────────────────────────────────────
    Q_INVOKABLE void arm();
    Q_INVOKABLE void disarm();
    Q_INVOKABLE void setMode(const QString &mode);
    Q_INVOKABLE void sendManualControl(int16_t x, int16_t y, int16_t z, int16_t r, uint16_t buttons);
    Q_INVOKABLE void requestDataStreams();

signals:
    void nameChanged();
    void vehicleTypeChanged();
    void connectedChanged();
    void attitudeChanged();
    void positionChanged();
    void navigationChanged();
    void batteryChanged();
    void gpsChanged();
    void armedChanged();
    void flightModeChanged();
    void baseModeChanged();

private slots:
    void checkHeartbeat();

private:
    void processHeartbeat(const mavlink_message_t &msg);
    void processAttitude(const mavlink_message_t &msg);
    void processGlobalPositionInt(const mavlink_message_t &msg);
    void processVfrHud(const mavlink_message_t &msg);
    void processSysStatus(const mavlink_message_t &msg);
    void processGpsRawInt(const mavlink_message_t &msg);
    void processScaledPressure(const mavlink_message_t &msg);
    void processBatteryStatus(const mavlink_message_t &msg);
    void processRcChannels(const mavlink_message_t &msg);

    QString resolveFlightMode(uint8_t baseMode, uint32_t customMode) const;
    void sendCommandLong(uint16_t command, float param1 = 0, float param2 = 0,
                         float param3 = 0, float param4 = 0, float param5 = 0,
                         float param6 = 0, float param7 = 0);

    uint8_t m_sysId;
    MavlinkManager *m_mavlink;
    QString m_name;
    VehicleType m_vehicleType = Unknown;
    bool m_connected = false;

    // Heartbeat timeout
    QTimer m_heartbeatTimer;
    QElapsedTimer m_lastHeartbeat;

    // Attitude
    double m_roll = 0;
    double m_pitch = 0;
    double m_yaw = 0;

    // Position
    double m_latitude = 0;
    double m_longitude = 0;
    double m_altitude = 0;
    double m_depth = 0;

    // Navigation
    double m_groundSpeed = 0;
    double m_climbRate = 0;
    double m_throttle = 0;

    // Battery
    double m_batteryVoltage = 0;
    int m_batteryPercent = -1;
    double m_batteryCurrent = 0;

    // GPS
    int m_gpsFixType = 0;
    int m_gpsSatCount = 0;
    int m_gpsHdop = 9999;

    // State
    bool m_armed = false;
    QString m_flightMode = "UNKNOWN";
    uint8_t m_baseMode = 0;
    uint32_t m_customMode = 0;

    // Constants
    static constexpr int HEARTBEAT_TIMEOUT_MS = 3000;
    static constexpr uint8_t GCS_SYSID = 255;
    static constexpr uint8_t GCS_COMPID = 190;
};

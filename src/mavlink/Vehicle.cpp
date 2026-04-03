#include "Vehicle.h"
#include "MavlinkManager.h"
#include <QtMath>
#include <QDebug>

Vehicle::Vehicle(uint8_t sysId, MavlinkManager *mavlink, QObject *parent)
    : QObject(parent)
    , m_sysId(sysId)
    , m_mavlink(mavlink)
{
    m_name = QString("Vehicle %1").arg(sysId);

    // Check for heartbeat timeout every second
    connect(&m_heartbeatTimer, &QTimer::timeout, this, &Vehicle::checkHeartbeat);
    m_heartbeatTimer.start(1000);
}

void Vehicle::handleMessage(const mavlink_message_t &msg)
{
    switch (msg.msgid) {
    case MAVLINK_MSG_ID_HEARTBEAT:
        processHeartbeat(msg);
        break;
    case MAVLINK_MSG_ID_ATTITUDE:
        processAttitude(msg);
        break;
    case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
        processGlobalPositionInt(msg);
        break;
    case MAVLINK_MSG_ID_VFR_HUD:
        processVfrHud(msg);
        break;
    case MAVLINK_MSG_ID_SYS_STATUS:
        processSysStatus(msg);
        break;
    case MAVLINK_MSG_ID_GPS_RAW_INT:
        processGpsRawInt(msg);
        break;
    case MAVLINK_MSG_ID_SCALED_PRESSURE:
        processScaledPressure(msg);
        break;
    case MAVLINK_MSG_ID_BATTERY_STATUS:
        processBatteryStatus(msg);
        break;
    case MAVLINK_MSG_ID_RC_CHANNELS:
        processRcChannels(msg);
        break;
    case MAVLINK_MSG_ID_COMMAND_ACK:
        processCommandAck(msg);
        break;
    }
}

// ─── Message Processors ─────────────────────────────────────────────────────

void Vehicle::processHeartbeat(const mavlink_message_t &msg)
{
    mavlink_heartbeat_t hb;
    mavlink_msg_heartbeat_decode(&msg, &hb);

    m_lastHeartbeat.restart();

    if (!m_connected) {
        m_connected = true;
        emit connectedChanged();
        requestDataStreams();
    }

    // Detect vehicle type
    VehicleType newType = Unknown;
    if (hb.type == MAV_TYPE_SUBMARINE) {
        newType = ROV;
    } else if (hb.type == MAV_TYPE_SURFACE_BOAT) {
        newType = USV;
    }

    if (newType != m_vehicleType) {
        m_vehicleType = newType;
        if (m_vehicleType == ROV) {
            m_name = QString("ROV-%1").arg(m_sysId);
        } else if (m_vehicleType == USV) {
            m_name = QString("USV-%1").arg(m_sysId);
        }
        emit vehicleTypeChanged();
        emit nameChanged();
    }

    // Armed state
    bool newArmed = (hb.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
    if (newArmed != m_armed) {
        m_armed = newArmed;
        qDebug() << "Vehicle" << m_name << ": Armed state changed to" << (m_armed ? "ARMED" : "DISARMED");
        emit armedChanged();
    }

    // Flight mode
    if (hb.base_mode != m_baseMode || hb.custom_mode != m_customMode) {
        m_baseMode = hb.base_mode;
        m_customMode = hb.custom_mode;
        m_flightMode = resolveFlightMode(hb.base_mode, hb.custom_mode);
        emit flightModeChanged();
        emit baseModeChanged();
    }
}

void Vehicle::processAttitude(const mavlink_message_t &msg)
{
    mavlink_attitude_t att;
    mavlink_msg_attitude_decode(&msg, &att);

    m_roll = qRadiansToDegrees(static_cast<double>(att.roll));
    m_pitch = qRadiansToDegrees(static_cast<double>(att.pitch));
    m_yaw = qRadiansToDegrees(static_cast<double>(att.yaw));

    emit attitudeChanged();
}

void Vehicle::processGlobalPositionInt(const mavlink_message_t &msg)
{
    mavlink_global_position_int_t pos;
    mavlink_msg_global_position_int_decode(&msg, &pos);

    m_latitude = pos.lat / 1e7;
    m_longitude = pos.lon / 1e7;
    m_altitude = pos.alt / 1000.0;

    // For ROV, relative_alt is often negative (depth below surface)
    if (m_vehicleType == ROV) {
        m_depth = -pos.relative_alt / 1000.0;  // Positive depth below surface
    }

    emit positionChanged();
}

void Vehicle::processVfrHud(const mavlink_message_t &msg)
{
    mavlink_vfr_hud_t hud;
    mavlink_msg_vfr_hud_decode(&msg, &hud);

    m_groundSpeed = hud.groundspeed;
    m_climbRate = hud.climb;
    m_throttle = hud.throttle;

    emit navigationChanged();
}

void Vehicle::processSysStatus(const mavlink_message_t &msg)
{
    mavlink_sys_status_t sys;
    mavlink_msg_sys_status_decode(&msg, &sys);

    m_batteryVoltage = sys.voltage_battery / 1000.0;
    m_batteryCurrent = sys.current_battery / 100.0;
    m_batteryPercent = sys.battery_remaining;

    emit batteryChanged();
}

void Vehicle::processGpsRawInt(const mavlink_message_t &msg)
{
    mavlink_gps_raw_int_t gps;
    mavlink_msg_gps_raw_int_decode(&msg, &gps);

    m_gpsFixType = gps.fix_type;
    m_gpsSatCount = gps.satellites_visible;
    m_gpsHdop = gps.eph;

    emit gpsChanged();
}

void Vehicle::processScaledPressure(const mavlink_message_t &msg)
{
    // Used for ROV depth calculation from external pressure sensor
    mavlink_scaled_pressure_t press;
    mavlink_msg_scaled_pressure_decode(&msg, &press);

    if (m_vehicleType == ROV) {
        // press_diff is differential pressure in hPa
        // 1 meter of water = ~98.1 hPa
        double depthFromPressure = press.press_diff / 98.1;
        if (depthFromPressure > 0) {
            m_depth = depthFromPressure;
            emit positionChanged();
        }
    }
}

void Vehicle::processBatteryStatus(const mavlink_message_t &msg)
{
    mavlink_battery_status_t bat;
    mavlink_msg_battery_status_decode(&msg, &bat);

    if (bat.battery_remaining >= 0) {
        m_batteryPercent = bat.battery_remaining;
        emit batteryChanged();
    }
}

void Vehicle::processRcChannels(const mavlink_message_t &msg)
{
    // Can be used for RC override display
    // Currently just tracking — extend as needed
}

void Vehicle::processCommandAck(const mavlink_message_t &msg)
{
    mavlink_command_ack_t ack;
    mavlink_msg_command_ack_decode(&msg, &ack);

    QString cmdName;
    switch (ack.command) {
    case MAV_CMD_COMPONENT_ARM_DISARM: cmdName = "ARM/DISARM"; break;
    case MAV_CMD_DO_SET_MODE: cmdName = "SET_MODE"; break;
    default: cmdName = QString::number(ack.command); break;
    }

    QString resultStr;
    switch (ack.result) {
    case MAV_RESULT_ACCEPTED: resultStr = "ACCEPTED"; break;
    case MAV_RESULT_TEMPORARILY_REJECTED: resultStr = "TEMPORARILY_REJECTED"; break;
    case MAV_RESULT_DENIED: resultStr = "DENIED"; break;
    case MAV_RESULT_UNSUPPORTED: resultStr = "UNSUPPORTED"; break;
    case MAV_RESULT_FAILED: resultStr = "FAILED"; break;
    default: resultStr = QString("RESULT_%1").arg(ack.result); break;
    }

    qDebug() << "Vehicle" << m_name << ": COMMAND_ACK" << cmdName << "=" << resultStr;
}

// ─── Commands ───────────────────────────────────────────────────────────────

void Vehicle::arm()
{
    qDebug() << "Vehicle" << m_name << ": Sending ARM command";
    sendCommandLong(MAV_CMD_COMPONENT_ARM_DISARM, 1.0f);
}

void Vehicle::disarm()
{
    qDebug() << "Vehicle" << m_name << ": Sending DISARM command";
    sendCommandLong(MAV_CMD_COMPONENT_ARM_DISARM, 0.0f);
}

void Vehicle::setMode(const QString &mode)
{
    // ArduSub modes
    static const QMap<QString, uint32_t> subModes = {
        {"STABILIZE", 0}, {"ACRO", 1}, {"ALT_HOLD", 2},
        {"AUTO", 3}, {"GUIDED", 4}, {"CIRCLE", 7},
        {"SURFACE", 9}, {"POSHOLD", 16}, {"MANUAL", 19},
        {"MOTOR_DETECT", 20}
    };

    // ArduBoat/Rover modes
    static const QMap<QString, uint32_t> boatModes = {
        {"MANUAL", 0}, {"ACRO", 1}, {"STEERING", 3},
        {"HOLD", 4}, {"LOITER", 5}, {"FOLLOW", 6},
        {"SIMPLE", 7}, {"DOCK", 8}, {"AUTO", 10},
        {"RTL", 11}, {"SMART_RTL", 12}, {"GUIDED", 15}
    };

    const auto &modeMap = (m_vehicleType == ROV) ? subModes : boatModes;
    auto it = modeMap.find(mode.toUpper());

    if (it != modeMap.end()) {
        mavlink_message_t msg;
        mavlink_msg_set_mode_pack(
            GCS_SYSID, GCS_COMPID, &msg,
            m_sysId,
            MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
            it.value()
        );
        m_mavlink->sendToVehicle(msg, m_sysId);
    } else {
        qWarning() << "Vehicle::setMode: Unknown mode" << mode << "for" << m_name;
    }
}

void Vehicle::sendManualControl(int16_t x, int16_t y, int16_t z, int16_t r, uint16_t buttons)
{
    mavlink_message_t msg;
    mavlink_msg_manual_control_pack(
        GCS_SYSID, GCS_COMPID, &msg,
        m_sysId,
        x, y, z, r, buttons,
        0,    // buttons2
        0,    // enabled_extensions
        0, 0, // s, t
        0, 0, 0, 0, 0, 0  // aux1-aux6
    );
    m_mavlink->sendToVehicle(msg, m_sysId);
}

void Vehicle::requestDataStreams()
{
    // Request all data streams at reasonable rates
    struct StreamRequest {
        uint8_t streamId;
        uint16_t rateHz;
    };

    const StreamRequest streams[] = {
        {MAV_DATA_STREAM_RAW_SENSORS, 2},
        {MAV_DATA_STREAM_EXTENDED_STATUS, 2},
        {MAV_DATA_STREAM_RC_CHANNELS, 2},
        {MAV_DATA_STREAM_POSITION, 4},
        {MAV_DATA_STREAM_EXTRA1, 10},  // Attitude
        {MAV_DATA_STREAM_EXTRA2, 4},   // VFR_HUD
        {MAV_DATA_STREAM_EXTRA3, 2},   // Battery
    };

    for (const auto &stream : streams) {
        mavlink_message_t msg;
        mavlink_msg_request_data_stream_pack(
            GCS_SYSID, GCS_COMPID, &msg,
            m_sysId, 0,  // target sysid, compid (0 = all components)
            stream.streamId,
            stream.rateHz,
            1  // start
        );
        m_mavlink->sendToVehicle(msg, m_sysId);
    }
}

void Vehicle::sendCommandLong(uint16_t command, float param1, float param2,
                               float param3, float param4, float param5,
                               float param6, float param7)
{
    mavlink_message_t msg;
    mavlink_msg_command_long_pack(
        GCS_SYSID, GCS_COMPID, &msg,
        m_sysId, 0,  // target sysid, compid
        command,
        0,  // confirmation
        param1, param2, param3, param4, param5, param6, param7
    );
    m_mavlink->sendToVehicle(msg, m_sysId);
}

void Vehicle::checkHeartbeat()
{
    if (m_connected && m_lastHeartbeat.elapsed() > HEARTBEAT_TIMEOUT_MS) {
        m_connected = false;
        emit connectedChanged();
        qDebug() << "Vehicle" << m_name << "disconnected (heartbeat timeout)";
    }
}

QString Vehicle::resolveFlightMode(uint8_t baseMode, uint32_t customMode) const
{
    if (!(baseMode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED)) {
        return "UNKNOWN";
    }

    if (m_vehicleType == ROV) {
        // ArduSub custom modes
        static const QMap<uint32_t, QString> modes = {
            {0, "STABILIZE"}, {1, "ACRO"}, {2, "ALT_HOLD"},
            {3, "AUTO"}, {4, "GUIDED"}, {7, "CIRCLE"},
            {9, "SURFACE"}, {16, "POSHOLD"}, {19, "MANUAL"},
            {20, "MOTOR_DETECT"}
        };
        return modes.value(customMode, QString("MODE_%1").arg(customMode));
    } else if (m_vehicleType == USV) {
        // ArduRover/Boat custom modes
        static const QMap<uint32_t, QString> modes = {
            {0, "MANUAL"}, {1, "ACRO"}, {3, "STEERING"},
            {4, "HOLD"}, {5, "LOITER"}, {6, "FOLLOW"},
            {7, "SIMPLE"}, {8, "DOCK"}, {10, "AUTO"},
            {11, "RTL"}, {12, "SMART_RTL"}, {15, "GUIDED"}
        };
        return modes.value(customMode, QString("MODE_%1").arg(customMode));
    }

    return QString("MODE_%1").arg(customMode);
}

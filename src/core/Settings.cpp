#include "Settings.h"
#include <QVariantMap>
#include <QMap>

Settings::Settings(QObject *parent)
    : QObject(parent)
    , m_settings("RovoControl", "RovoControl")
{
}

// ─── ROV ────────────────────────────────────────────────────────────────────

int Settings::rovSysId() const {
    return m_settings.value("rov/sysid", 1).toInt();
}
void Settings::setRovSysId(int id) {
    if (rovSysId() != id) { m_settings.setValue("rov/sysid", id); emit rovSysIdChanged(); }
}

int Settings::rovPort() const {
    return m_settings.value("rov/port", 14550).toInt();
}
void Settings::setRovPort(int port) {
    if (rovPort() != port) { m_settings.setValue("rov/port", port); emit rovPortChanged(); }
}

QString Settings::rovCamera1() const {
    return m_settings.value("rov/camera1", "rtsp://192.168.2.2:8554/video0").toString();
}
void Settings::setRovCamera1(const QString &uri) {
    if (rovCamera1() != uri) { m_settings.setValue("rov/camera1", uri); emit rovCamera1Changed(); }
}

QString Settings::rovCamera2() const {
    return m_settings.value("rov/camera2", "rtsp://192.168.2.2:8554/video1").toString();
}
void Settings::setRovCamera2(const QString &uri) {
    if (rovCamera2() != uri) { m_settings.setValue("rov/camera2", uri); emit rovCamera2Changed(); }
}

// ─── USV ────────────────────────────────────────────────────────────────────

int Settings::usvSysId() const {
    return m_settings.value("usv/sysid", 2).toInt();
}
void Settings::setUsvSysId(int id) {
    if (usvSysId() != id) { m_settings.setValue("usv/sysid", id); emit usvSysIdChanged(); }
}

int Settings::usvPort() const {
    return m_settings.value("usv/port", 14551).toInt();
}
void Settings::setUsvPort(int port) {
    if (usvPort() != port) { m_settings.setValue("usv/port", port); emit usvPortChanged(); }
}

QString Settings::usvCamera1() const {
    return m_settings.value("usv/camera1", "rtsp://192.168.3.2:8554/video0").toString();
}
void Settings::setUsvCamera1(const QString &uri) {
    if (usvCamera1() != uri) { m_settings.setValue("usv/camera1", uri); emit usvCamera1Changed(); }
}

QString Settings::usvCamera2() const {
    return m_settings.value("usv/camera2", "rtsp://192.168.3.2:8554/video1").toString();
}
void Settings::setUsvCamera2(const QString &uri) {
    if (usvCamera2() != uri) { m_settings.setValue("usv/camera2", uri); emit usvCamera2Changed(); }
}

// ─── Joystick Persistence ───────────────────────────────────────────────────

static QString sanitizeName(const QString &name) {
    QString s = name;
    s.replace(' ', '_').replace('/', '_').replace('\\', '_');
    return s;
}

void Settings::saveJoystickConfig(const QString &name, const QVariantMap &config)
{
    QString key = "joystick/" + sanitizeName(name);
    m_settings.beginGroup(key);
    for (auto it = config.constBegin(); it != config.constEnd(); ++it) {
        if (it.key() == "buttonActions") {
            // Save button actions as sub-keys
            QVariantMap btnMap = it.value().toMap();
            m_settings.beginGroup("buttons");
            m_settings.remove("");  // clear old button keys
            for (auto bt = btnMap.constBegin(); bt != btnMap.constEnd(); ++bt) {
                m_settings.setValue(bt.key(), bt.value());
            }
            m_settings.endGroup();
        } else {
            m_settings.setValue(it.key(), it.value());
        }
    }
    m_settings.endGroup();
}

QVariantMap Settings::loadJoystickConfig(const QString &name) const
{
    QString key = "joystick/" + sanitizeName(name);
    QVariantMap config;

    // Use a non-const copy to call beginGroup
    QSettings &s = const_cast<QSettings&>(m_settings);
    s.beginGroup(key);
    QStringList keys = s.childKeys();
    for (const QString &k : keys) {
        config[k] = s.value(k);
    }
    // Load button actions
    s.beginGroup("buttons");
    QStringList btnKeys = s.childKeys();
    if (!btnKeys.isEmpty()) {
        QVariantMap btnMap;
        for (const QString &bk : btnKeys) {
            btnMap[bk] = s.value(bk);
        }
        config["buttonActions"] = btnMap;
    }
    s.endGroup();
    s.endGroup();

    return config;
}

void Settings::migrateAxisZR()
{
    // Migration v1: swap Z/R
    if (!m_settings.value("migrations/axisZR_swapped", false).toBool()) {
        m_settings.beginGroup("joystick");
        QStringList groups = m_settings.childGroups();
        for (const QString &g : groups) {
            if (g == "routing") continue;
            m_settings.beginGroup(g);
            if (m_settings.contains("axisMapZ") || m_settings.contains("axisMapR")) {
                int oldZ = m_settings.value("axisMapZ", 2).toInt();
                int oldR = m_settings.value("axisMapR", 3).toInt();
                m_settings.setValue("axisMapZ", oldR);
                m_settings.setValue("axisMapR", oldZ);
            }
            m_settings.endGroup();
        }
        m_settings.endGroup();
        m_settings.setValue("migrations/axisZR_swapped", true);
        qDebug() << "Settings: Migrated axis Z/R swap";
    }

    // Migration v2: swap X/Y
    if (!m_settings.value("migrations/axisXY_swapped", false).toBool()) {
        m_settings.beginGroup("joystick");
        QStringList groups = m_settings.childGroups();
        for (const QString &g : groups) {
            if (g == "routing") continue;
            m_settings.beginGroup(g);
            if (m_settings.contains("axisMapX") || m_settings.contains("axisMapY")) {
                int oldX = m_settings.value("axisMapX", 0).toInt();
                int oldY = m_settings.value("axisMapY", 1).toInt();
                m_settings.setValue("axisMapX", oldY);
                m_settings.setValue("axisMapY", oldX);
            }
            m_settings.endGroup();
        }
        m_settings.endGroup();
        m_settings.setValue("migrations/axisXY_swapped", true);
        qDebug() << "Settings: Migrated axis X/Y swap";
    }
}

void Settings::saveJoystickRouting(const QMap<QString, int> &routing)
{
    m_settings.beginGroup("joystick/routing");
    m_settings.remove("");  // clear old routing
    for (auto it = routing.constBegin(); it != routing.constEnd(); ++it) {
        m_settings.setValue(sanitizeName(it.key()), it.value());
    }
    m_settings.endGroup();
}

QMap<QString, int> Settings::loadJoystickRouting() const
{
    QMap<QString, int> routing;
    QSettings &s = const_cast<QSettings&>(m_settings);
    s.beginGroup("joystick/routing");
    QStringList keys = s.childKeys();
    for (const QString &k : keys) {
        // Key is sanitized name, but we need to match against actual joystick names
        // Store as-is; matching done by JoystickManager with sanitized lookup
        routing[k] = s.value(k).toInt();
    }
    s.endGroup();
    return routing;
}

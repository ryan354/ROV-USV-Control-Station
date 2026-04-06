#pragma once

#include <QObject>
#include <QTimer>
#include <QList>
#include <QMap>
#include <QVariantMap>

class Joystick;
class VehicleManager;
class Vehicle;
class Settings;

class JoystickManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int joystickCount READ joystickCount NOTIFY joysticksChanged)
    Q_PROPERTY(QList<QObject*> joysticks READ joystickList NOTIFY joysticksChanged)
    Q_PROPERTY(bool available READ isAvailable CONSTANT)
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)

public:
    explicit JoystickManager(QObject *parent = nullptr);
    ~JoystickManager();

    int joystickCount() const { return m_joysticks.size(); }
    QList<QObject*> joystickList() const;
    bool isAvailable() const { return m_sdlInitialized; }
    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool e);

    Q_INVOKABLE Joystick* joystick(int index) const;
    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    // Vehicle routing
    Q_INVOKABLE void assignJoystickToVehicle(const QString &joystickName, int sysId);
    Q_INVOKABLE int vehicleForJoystick(const QString &joystickName) const;

    // Config
    void setVehicleManager(VehicleManager *vm) { m_vehicleManager = vm; }
    void setSettings(Settings *s) { m_settings = s; }
    void loadConfig();
    Q_INVOKABLE void saveConfig();

signals:
    void joysticksChanged();
    void enabledChanged();

private slots:
    void poll();

private:
    void enumerate();
    void dispatchAction(Vehicle *vehicle, const QString &action);

    QTimer m_pollTimer;
    QList<Joystick*> m_joysticks;
    bool m_sdlInitialized = false;
    bool m_enabled = true;
    int m_sendCounter = 0;

    // Button action cooldown: prevent rapid-fire arm/disarm spam
    QMap<QString, qint64> m_actionCooldown;  // action → last trigger timestamp
    static constexpr int ACTION_COOLDOWN_MS = 1000;

    // Routing: joystick name → vehicle sysid (0 = unassigned)
    QMap<QString, int> m_joystickVehicleMap;

    VehicleManager *m_vehicleManager = nullptr;
    Settings *m_settings = nullptr;

    static constexpr int POLL_INTERVAL_MS = 20;  // 50 Hz
};

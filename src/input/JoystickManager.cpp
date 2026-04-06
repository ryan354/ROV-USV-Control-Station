#include "JoystickManager.h"
#include "Joystick.h"
#include "mavlink/VehicleManager.h"
#include "mavlink/Vehicle.h"
#include "core/Settings.h"
#include <QDebug>
#include <QDateTime>

#ifdef HAS_SDL2
#include <SDL.h>
#endif

JoystickManager::JoystickManager(QObject *parent)
    : QObject(parent)
{
#ifdef HAS_SDL2
    if (SDL_Init(SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK) == 0) {
        m_sdlInitialized = true;
        qDebug() << "JoystickManager: SDL2 initialized";
    } else {
        qWarning() << "JoystickManager: SDL2 init failed:" << SDL_GetError();
    }
#else
    qDebug() << "JoystickManager: SDL2 not available";
#endif

    connect(&m_pollTimer, &QTimer::timeout, this, &JoystickManager::poll);
}

JoystickManager::~JoystickManager()
{
    stop();
#ifdef HAS_SDL2
    if (m_sdlInitialized) SDL_Quit();
#endif
}

QList<QObject*> JoystickManager::joystickList() const
{
    QList<QObject*> list;
    for (auto *js : m_joysticks) list.append(js);
    return list;
}

Joystick* JoystickManager::joystick(int index) const
{
    if (index >= 0 && index < m_joysticks.size()) return m_joysticks.at(index);
    return nullptr;
}

void JoystickManager::setEnabled(bool e)
{
    if (m_enabled != e) { m_enabled = e; emit enabledChanged(); }
}

void JoystickManager::start()
{
#ifdef HAS_SDL2
    if (m_sdlInitialized) {
        enumerate();
        m_pollTimer.start(POLL_INTERVAL_MS);
        qDebug() << "JoystickManager: Started polling," << m_joysticks.size() << "joystick(s)";
    }
#endif
}

void JoystickManager::stop()
{
    m_pollTimer.stop();
    qDeleteAll(m_joysticks);
    m_joysticks.clear();
    emit joysticksChanged();
}

// ─── Vehicle Routing ────────────────────────────────────────────────────────

void JoystickManager::assignJoystickToVehicle(const QString &joystickName, int sysId)
{
    m_joystickVehicleMap[joystickName] = sysId;
}

int JoystickManager::vehicleForJoystick(const QString &joystickName) const
{
    return m_joystickVehicleMap.value(joystickName, 0);
}

// ─── Config Persistence ─────────────────────────────────────────────────────

void JoystickManager::loadConfig()
{
    if (!m_settings) return;

    // One-time migration: swap Z/R axis defaults (v0.1.0 → v0.2.0)
    m_settings->migrateAxisZR();

    m_joystickVehicleMap = m_settings->loadJoystickRouting();

    // Per-joystick settings are applied after enumerate() creates the objects
    qDebug() << "JoystickManager: Config loaded, routing:" << m_joystickVehicleMap;
}

void JoystickManager::saveConfig()
{
    if (!m_settings) return;

    m_settings->saveJoystickRouting(m_joystickVehicleMap);

    for (auto *js : m_joysticks) {
        QVariantMap config;
        config["deadzone"] = js->deadzone();
        config["expo"] = js->expo();
        config["axisMapX"] = js->axisMapX();
        config["axisMapY"] = js->axisMapY();
        config["axisMapZ"] = js->axisMapZ();
        config["axisMapR"] = js->axisMapR();
        config["invertX"] = js->invertX();
        config["invertY"] = js->invertY();
        config["invertZ"] = js->invertZ();
        config["invertR"] = js->invertR();
        config["buttonActions"] = js->buttonActionsVariant();
        m_settings->saveJoystickConfig(js->name(), config);
    }

    qDebug() << "JoystickManager: Config saved";
}

// ─── Enumeration ────────────────────────────────────────────────────────────

void JoystickManager::enumerate()
{
#ifdef HAS_SDL2
    qDeleteAll(m_joysticks);
    m_joysticks.clear();

    int count = SDL_NumJoysticks();
    for (int i = 0; i < count; ++i) {
        auto *js = new Joystick(i, this);
        if (js->isOpen()) {
            m_joysticks.append(js);
            qDebug() << "JoystickManager: Found" << js->name()
                     << "(" << js->axisCount() << "axes," << js->buttonCount() << "buttons)";

            // Load saved config for this joystick
            if (m_settings) {
                QVariantMap config = m_settings->loadJoystickConfig(js->name());
                if (!config.isEmpty()) {
                    js->setDeadzone(config.value("deadzone", 0.05).toDouble());
                    js->setExpo(config.value("expo", 0.3).toDouble());
                    js->setAxisMapX(config.value("axisMapX", 1).toInt());
                    js->setAxisMapY(config.value("axisMapY", 0).toInt());
                    js->setAxisMapZ(config.value("axisMapZ", 3).toInt());
                    js->setAxisMapR(config.value("axisMapR", 2).toInt());
                    js->setInvertX(config.value("invertX", false).toBool());
                    js->setInvertY(config.value("invertY", true).toBool());
                    js->setInvertZ(config.value("invertZ", false).toBool());
                    js->setInvertR(config.value("invertR", false).toBool());
                    QVariantMap btnMap = config.value("buttonActions").toMap();
                    if (!btnMap.isEmpty()) js->setButtonActionsVariant(btnMap);
                }
            }

            // Connect button press to action dispatch
            connect(js, &Joystick::buttonChanged, this, [this, js](int button, bool pressed) {
                if (!pressed) return;

                QString action = js->buttonAction(button);
                if (action.isEmpty()) return;

                qDebug() << "JoystickManager: Button" << button << "action:" << action;

                if (!m_enabled) {
                    qDebug() << "JoystickManager: Joystick input disabled";
                    return;
                }
                if (!m_vehicleManager) {
                    qDebug() << "JoystickManager: No vehicle manager";
                    return;
                }

                int sysId = m_joystickVehicleMap.value(js->name(), 0);
                if (sysId <= 0) {
                    qDebug() << "JoystickManager: Joystick" << js->name() << "not assigned to any vehicle";
                    return;
                }

                Vehicle *v = m_vehicleManager->vehicleBySysId(static_cast<uint8_t>(sysId));
                if (!v) {
                    qDebug() << "JoystickManager: Vehicle sysid" << sysId << "not found";
                    return;
                }
                if (!v->isConnected()) {
                    qDebug() << "JoystickManager: Vehicle sysid" << sysId << "not connected";
                    return;
                }

                // Cooldown: prevent rapid-fire (e.g. arm/disarm spam from held button)
                qint64 now = QDateTime::currentMSecsSinceEpoch();
                QString cooldownKey = js->name() + ":" + action;
                if (now - m_actionCooldown.value(cooldownKey, 0) < ACTION_COOLDOWN_MS) {
                    return;  // still in cooldown
                }
                m_actionCooldown[cooldownKey] = now;

                qDebug() << "JoystickManager: Dispatching" << action << "to vehicle" << sysId;
                dispatchAction(v, action);
            });

        } else {
            delete js;
        }
    }

    // Default routing: first joystick → sysid 1 if no routing saved
    if (!m_joysticks.isEmpty() && m_joystickVehicleMap.isEmpty()) {
        m_joystickVehicleMap[m_joysticks.first()->name()] = 1;
    }

    emit joysticksChanged();
#endif
}

// ─── Polling + Send ─────────────────────────────────────────────────────────

void JoystickManager::poll()
{
#ifdef HAS_SDL2
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_JOYDEVICEADDED || event.type == SDL_JOYDEVICEREMOVED) {
            enumerate();
            return;
        }
    }

    m_sendCounter++;
    bool shouldSend = (m_sendCounter % 2 == 0); // 25 Hz from 50 Hz poll

    for (auto *js : m_joysticks) {
        js->update();

        if (shouldSend && m_enabled && m_vehicleManager) {
            int sysId = m_joystickVehicleMap.value(js->name(), 0);
            if (sysId > 0) {
                Vehicle *v = m_vehicleManager->vehicleBySysId(static_cast<uint8_t>(sysId));
                if (v && v->isConnected() && v->isArmed()) {
                    v->sendManualControl(
                        js->manualControlX(),
                        js->manualControlY(),
                        js->manualControlZ(),
                        js->manualControlR(),
                        js->manualControlButtons()
                    );
                }
            }
        }
    }
#endif
}

// ─── Action Dispatch ────────────────────────────────────────────────────────

void JoystickManager::dispatchAction(Vehicle *vehicle, const QString &action)
{
    if (action == "arm")                vehicle->arm();
    else if (action == "disarm")        vehicle->disarm();
    else if (action == "mode_manual")   vehicle->setMode("MANUAL");
    else if (action == "mode_stabilize")vehicle->setMode("STABILIZE");
    else if (action == "mode_depthhold")vehicle->setMode("ALT_HOLD");
    else if (action == "mode_poshold")  vehicle->setMode("POSHOLD");
    else if (action == "mode_auto")     vehicle->setMode("AUTO");
    else if (action == "mode_guided")   vehicle->setMode("GUIDED");
    else if (action == "mode_loiter")   vehicle->setMode("LOITER");
    else if (action == "mode_rtl")      vehicle->setMode("RTL");
    else if (action == "mode_hold")     vehicle->setMode("HOLD");
    else if (action == "mode_surface")  vehicle->setMode("SURFACE");
    else {
        qDebug() << "JoystickManager: Action" << action << "sent as button bit (handled by vehicle firmware)";
    }
}

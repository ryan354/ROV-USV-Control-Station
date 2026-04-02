#include "Joystick.h"
#include <QtMath>
#include <QDebug>

#ifdef HAS_SDL2
#include <SDL.h>
#endif

Joystick::Joystick(int deviceIndex, QObject *parent)
    : QObject(parent)
{
#ifdef HAS_SDL2
    if (SDL_IsGameController(deviceIndex)) {
        m_controller = SDL_GameControllerOpen(deviceIndex);
        if (m_controller) {
            m_joystick = SDL_GameControllerGetJoystick(m_controller);
            m_name = SDL_GameControllerName(m_controller);
            m_open = true;
        }
    } else {
        m_joystick = SDL_JoystickOpen(deviceIndex);
        if (m_joystick) {
            m_name = SDL_JoystickName(m_joystick);
            m_open = true;
        }
    }

    if (m_joystick) {
        m_axisCount = SDL_JoystickNumAxes(m_joystick);
        m_buttonCount = SDL_JoystickNumButtons(m_joystick);
        m_axes.resize(m_axisCount);
        m_buttons.resize(m_buttonCount);
    }
#else
    Q_UNUSED(deviceIndex)
    m_name = "No SDL2";
#endif
}

Joystick::~Joystick()
{
#ifdef HAS_SDL2
    if (m_controller) {
        SDL_GameControllerClose(m_controller);
    } else if (m_joystick) {
        SDL_JoystickClose(m_joystick);
    }
#endif
}

// ─── Mapped Axes ────────────────────────────────────────────────────────────

double Joystick::getMappedAxis(int physicalIndex, bool invert) const
{
    double raw = m_axes.value(physicalIndex, 0.0);
    double processed = applyDeadzoneAndExpo(raw);
    return invert ? -processed : processed;
}

double Joystick::axisX() const { return getMappedAxis(m_axisMapX, m_invertX); }
double Joystick::axisY() const { return getMappedAxis(m_axisMapY, m_invertY); }
double Joystick::axisZ() const { return getMappedAxis(m_axisMapZ, m_invertZ); }
double Joystick::axisR() const { return getMappedAxis(m_axisMapR, m_invertR); }

double Joystick::rawAxis(int index) const
{
    if (index >= 0 && index < m_axes.size()) return m_axes.at(index);
    return 0.0;
}

bool Joystick::button(int index) const
{
    if (index >= 0 && index < m_buttons.size()) return m_buttons.at(index);
    return false;
}

// ─── Deadzone / Expo ────────────────────────────────────────────────────────

void Joystick::setDeadzone(double dz)
{
    dz = qBound(0.0, dz, 0.5);
    if (!qFuzzyCompare(m_deadzone, dz)) { m_deadzone = dz; emit deadzoneChanged(); }
}

void Joystick::setExpo(double expo)
{
    expo = qBound(0.0, expo, 1.0);
    if (!qFuzzyCompare(m_expo, expo)) { m_expo = expo; emit expoChanged(); }
}

double Joystick::applyDeadzoneAndExpo(double value) const
{
    if (qAbs(value) < m_deadzone) return 0.0;

    double sign = value > 0 ? 1.0 : -1.0;
    double scaled = (qAbs(value) - m_deadzone) / (1.0 - m_deadzone);
    scaled = qBound(0.0, scaled, 1.0);

    double linear = scaled;
    double cubic = scaled * scaled * scaled;
    double result = (1.0 - m_expo) * linear + m_expo * cubic;

    return sign * result;
}

// ─── Button Actions ─────────────────────────────────────────────────────────

void Joystick::setButtonAction(int button, const QString &action)
{
    if (action.isEmpty() || action == "none") {
        m_buttonActions.remove(button);
    } else {
        m_buttonActions[button] = action;
    }
    emit buttonActionsChanged();
}

QString Joystick::buttonAction(int button) const
{
    return m_buttonActions.value(button, "");
}

QVariantMap Joystick::buttonActionsVariant() const
{
    QVariantMap map;
    for (auto it = m_buttonActions.constBegin(); it != m_buttonActions.constEnd(); ++it) {
        map.insert(QString::number(it.key()), it.value());
    }
    return map;
}

void Joystick::setButtonActionsVariant(const QVariantMap &map)
{
    m_buttonActions.clear();
    for (auto it = map.constBegin(); it != map.constEnd(); ++it) {
        m_buttonActions[it.key().toInt()] = it.value().toString();
    }
    emit buttonActionsChanged();
}

// ─── Update Loop ────────────────────────────────────────────────────────────

void Joystick::update()
{
#ifdef HAS_SDL2
    if (!m_joystick) return;

    bool axisUpdated = false;
    for (int i = 0; i < m_axisCount; ++i) {
        double raw = SDL_JoystickGetAxis(m_joystick, i) / 32767.0;
        if (!qFuzzyCompare(m_axes[i], raw)) {
            m_axes[i] = raw;
            axisUpdated = true;
        }
    }

    if (axisUpdated) emit axesChanged();

    for (int i = 0; i < m_buttonCount; ++i) {
        bool pressed = SDL_JoystickGetButton(m_joystick, i) != 0;
        if (m_buttons[i] != pressed) {
            m_buttons[i] = pressed;
            emit buttonChanged(i, pressed);
        }
    }
#endif
}

// ─── MAVLink Conversion ─────────────────────────────────────────────────────

int16_t Joystick::toManualControl(double normalizedValue) const
{
    return static_cast<int16_t>(qBound(-1000.0, normalizedValue * 1000.0, 1000.0));
}

int16_t Joystick::manualControlX() const { return toManualControl(axisX()); }
int16_t Joystick::manualControlY() const { return toManualControl(axisY()); }
int16_t Joystick::manualControlZ() const { return toManualControl(axisZ()); }
int16_t Joystick::manualControlR() const { return toManualControl(axisR()); }

uint16_t Joystick::manualControlButtons() const
{
    uint16_t buttons = 0;
    for (int i = 0; i < qMin(16, m_buttonCount); ++i) {
        if (m_buttons.value(i, false)) buttons |= (1 << i);
    }
    return buttons;
}

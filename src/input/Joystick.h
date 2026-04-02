#pragma once

#include <QObject>
#include <QVector>
#include <QString>
#include <QVariantMap>
#include <QMap>

#ifdef HAS_SDL2
struct _SDL_Joystick;
typedef struct _SDL_Joystick SDL_Joystick;
struct _SDL_GameController;
typedef struct _SDL_GameController SDL_GameController;
#endif

class Joystick : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(bool connected READ isOpen CONSTANT)
    Q_PROPERTY(int axisCount READ axisCount CONSTANT)
    Q_PROPERTY(int buttonCount READ buttonCount CONSTANT)

    // Mapped axes normalized to [-1.0, 1.0]
    Q_PROPERTY(double axisX READ axisX NOTIFY axesChanged)
    Q_PROPERTY(double axisY READ axisY NOTIFY axesChanged)
    Q_PROPERTY(double axisZ READ axisZ NOTIFY axesChanged)
    Q_PROPERTY(double axisR READ axisR NOTIFY axesChanged)

    // Axis mapping: which physical axis index feeds each logical axis
    Q_PROPERTY(int axisMapX READ axisMapX WRITE setAxisMapX NOTIFY axisMappingChanged)
    Q_PROPERTY(int axisMapY READ axisMapY WRITE setAxisMapY NOTIFY axisMappingChanged)
    Q_PROPERTY(int axisMapZ READ axisMapZ WRITE setAxisMapZ NOTIFY axisMappingChanged)
    Q_PROPERTY(int axisMapR READ axisMapR WRITE setAxisMapR NOTIFY axisMappingChanged)

    // Axis inversion
    Q_PROPERTY(bool invertX READ invertX WRITE setInvertX NOTIFY axisMappingChanged)
    Q_PROPERTY(bool invertY READ invertY WRITE setInvertY NOTIFY axisMappingChanged)
    Q_PROPERTY(bool invertZ READ invertZ WRITE setInvertZ NOTIFY axisMappingChanged)
    Q_PROPERTY(bool invertR READ invertR WRITE setInvertR NOTIFY axisMappingChanged)

    // Configuration
    Q_PROPERTY(double deadzone READ deadzone WRITE setDeadzone NOTIFY deadzoneChanged)
    Q_PROPERTY(double expo READ expo WRITE setExpo NOTIFY expoChanged)

    // Button actions
    Q_PROPERTY(QVariantMap buttonActions READ buttonActionsVariant WRITE setButtonActionsVariant NOTIFY buttonActionsChanged)

public:
    explicit Joystick(int deviceIndex, QObject *parent = nullptr);
    ~Joystick();

    QString name() const { return m_name; }
    bool isOpen() const { return m_open; }
    int axisCount() const { return m_axisCount; }
    int buttonCount() const { return m_buttonCount; }

    // Mapped axes (applies mapping index + inversion + deadzone + expo)
    double axisX() const;
    double axisY() const;
    double axisZ() const;
    double axisR() const;

    // Axis mapping
    int axisMapX() const { return m_axisMapX; }
    int axisMapY() const { return m_axisMapY; }
    int axisMapZ() const { return m_axisMapZ; }
    int axisMapR() const { return m_axisMapR; }
    void setAxisMapX(int v) { if (m_axisMapX != v) { m_axisMapX = v; emit axisMappingChanged(); } }
    void setAxisMapY(int v) { if (m_axisMapY != v) { m_axisMapY = v; emit axisMappingChanged(); } }
    void setAxisMapZ(int v) { if (m_axisMapZ != v) { m_axisMapZ = v; emit axisMappingChanged(); } }
    void setAxisMapR(int v) { if (m_axisMapR != v) { m_axisMapR = v; emit axisMappingChanged(); } }

    // Inversion
    bool invertX() const { return m_invertX; }
    bool invertY() const { return m_invertY; }
    bool invertZ() const { return m_invertZ; }
    bool invertR() const { return m_invertR; }
    void setInvertX(bool v) { if (m_invertX != v) { m_invertX = v; emit axisMappingChanged(); } }
    void setInvertY(bool v) { if (m_invertY != v) { m_invertY = v; emit axisMappingChanged(); } }
    void setInvertZ(bool v) { if (m_invertZ != v) { m_invertZ = v; emit axisMappingChanged(); } }
    void setInvertR(bool v) { if (m_invertR != v) { m_invertR = v; emit axisMappingChanged(); } }

    // Deadzone / Expo
    double deadzone() const { return m_deadzone; }
    void setDeadzone(double dz);
    double expo() const { return m_expo; }
    void setExpo(double expo);

    // Button actions
    Q_INVOKABLE void setButtonAction(int button, const QString &action);
    Q_INVOKABLE QString buttonAction(int button) const;
    QVariantMap buttonActionsVariant() const;
    void setButtonActionsVariant(const QVariantMap &map);

    // Raw access
    Q_INVOKABLE double rawAxis(int index) const;
    Q_INVOKABLE bool button(int index) const;

    // Called by JoystickManager at poll rate
    void update();

    // MAVLink manual_control values [-1000, 1000]
    int16_t manualControlX() const;
    int16_t manualControlY() const;
    int16_t manualControlZ() const;
    int16_t manualControlR() const;
    uint16_t manualControlButtons() const;

signals:
    void axesChanged();
    void buttonChanged(int button, bool pressed);
    void axisMappingChanged();
    void deadzoneChanged();
    void expoChanged();
    void buttonActionsChanged();

private:
    double getMappedAxis(int physicalIndex, bool invert) const;
    double applyDeadzoneAndExpo(double value) const;
    int16_t toManualControl(double normalizedValue) const;

    QString m_name;
    bool m_open = false;
    int m_axisCount = 0;
    int m_buttonCount = 0;

    QVector<double> m_axes;
    QVector<bool> m_buttons;

    // Axis mapping
    int m_axisMapX = 0;
    int m_axisMapY = 1;
    int m_axisMapZ = 2;
    int m_axisMapR = 3;
    bool m_invertX = false;
    bool m_invertY = true;   // Y traditionally inverted
    bool m_invertZ = false;
    bool m_invertR = false;

    double m_deadzone = 0.05;
    double m_expo = 0.3;

    // Button action mapping: button index → action name
    QMap<int, QString> m_buttonActions;

#ifdef HAS_SDL2
    SDL_GameController *m_controller = nullptr;
    SDL_Joystick *m_joystick = nullptr;
#endif
};

#pragma once

#include <QObject>
#include <QSettings>
#include <QString>

class Settings : public QObject
{
    Q_OBJECT

    // ─── ROV Settings ───────────────────────────────────────────────────────
    Q_PROPERTY(int rovSysId READ rovSysId WRITE setRovSysId NOTIFY rovSysIdChanged)
    Q_PROPERTY(int rovPort READ rovPort WRITE setRovPort NOTIFY rovPortChanged)
    Q_PROPERTY(QString rovCamera1 READ rovCamera1 WRITE setRovCamera1 NOTIFY rovCamera1Changed)
    Q_PROPERTY(QString rovCamera2 READ rovCamera2 WRITE setRovCamera2 NOTIFY rovCamera2Changed)

    // ─── USV Settings ───────────────────────────────────────────────────────
    Q_PROPERTY(int usvSysId READ usvSysId WRITE setUsvSysId NOTIFY usvSysIdChanged)
    Q_PROPERTY(int usvPort READ usvPort WRITE setUsvPort NOTIFY usvPortChanged)
    Q_PROPERTY(QString usvCamera1 READ usvCamera1 WRITE setUsvCamera1 NOTIFY usvCamera1Changed)
    Q_PROPERTY(QString usvCamera2 READ usvCamera2 WRITE setUsvCamera2 NOTIFY usvCamera2Changed)

public:
    explicit Settings(QObject *parent = nullptr);

    // ROV
    int rovSysId() const;
    void setRovSysId(int id);
    int rovPort() const;
    void setRovPort(int port);
    QString rovCamera1() const;
    void setRovCamera1(const QString &uri);
    QString rovCamera2() const;
    void setRovCamera2(const QString &uri);

    // USV
    int usvSysId() const;
    void setUsvSysId(int id);
    int usvPort() const;
    void setUsvPort(int port);
    QString usvCamera1() const;
    void setUsvCamera1(const QString &uri);
    QString usvCamera2() const;
    void setUsvCamera2(const QString &uri);

    // Legacy compat
    int mavlinkPort() const { return rovPort(); }

    // Joystick persistence
    void saveJoystickConfig(const QString &name, const QVariantMap &config);
    QVariantMap loadJoystickConfig(const QString &name) const;
    void saveJoystickRouting(const QMap<QString, int> &routing);
    QMap<QString, int> loadJoystickRouting() const;

signals:
    void rovSysIdChanged();
    void rovPortChanged();
    void rovCamera1Changed();
    void rovCamera2Changed();
    void usvSysIdChanged();
    void usvPortChanged();
    void usvCamera1Changed();
    void usvCamera2Changed();

private:
    QSettings m_settings;
};

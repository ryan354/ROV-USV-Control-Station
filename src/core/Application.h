#pragma once

#include <QObject>

class Application : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString appName READ appName CONSTANT)

public:
    explicit Application(QObject *parent = nullptr);

    QString version() const { return QStringLiteral("0.1.0"); }
    QString appName() const { return QStringLiteral("RovoControl"); }
};

#include <QByteArray>
#include <QString>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#ifdef HAS_WEBENGINE
#include <QtWebEngineQuick>
#endif
#include <QQmlContext>
#include <QtQml>
#include <QDebug>

#include "core/Settings.h"
#include "mavlink/VehicleManager.h"
#include "mavlink/MavlinkManager.h"
#include "video/VideoManager.h"
#include "video/VideoReceiver.h"
#include "input/JoystickManager.h"
#include "input/Joystick.h"
#include "map/MapBridge.h"

int main(int argc, char *argv[])
{
    // Add GStreamer bin to PATH so plugins can find their DLL dependencies
#ifdef HAS_GSTREAMER
    {
        QString gstBin = qEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", "C:\\gstreamer\\1.0\\msvc_x86_64");
        if (!gstBin.endsWith("\\bin")) gstBin += "\\bin";
        else gstBin = gstBin.chopped(1); // remove trailing backslash if root path

        // Check both possible locations
        QString gstRoot = qEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", "C:\\gstreamer\\1.0\\msvc_x86_64");
        while (gstRoot.endsWith('\\') || gstRoot.endsWith('/')) gstRoot.chop(1);
        QString binPath = gstRoot + "\\bin";

        QByteArray currentPath = qgetenv("PATH");
        if (!currentPath.contains(binPath.toUtf8())) {
            qputenv("PATH", binPath.toUtf8() + ";" + currentPath);
        }
    }
#endif

#ifdef HAS_WEBENGINE
    QtWebEngineQuick::initialize();
#endif
    QGuiApplication app(argc, argv);
    app.setApplicationName("RovoControl");
    app.setOrganizationName("RovoControl");
    app.setApplicationVersion("0.1.0");

    // Use Material style
    QQuickStyle::setStyle("Material");

    // Create core singletons
    Settings settings;
    MavlinkManager mavlinkManager;
    VehicleManager vehicleManager(&mavlinkManager);
    VideoManager videoManager;
    JoystickManager joystickManager;
    MapBridge mapBridge;

    // Connect MAVLink manager to vehicle manager
    QObject::connect(&mavlinkManager, &MavlinkManager::messageReceived,
                     &vehicleManager, &VehicleManager::handleMavlinkMessage);

    // Connect vehicle updates to map bridge
    QObject::connect(&vehicleManager, &VehicleManager::vehiclePositionChanged,
                     &mapBridge, &MapBridge::updateVehiclePosition);

    // Start MAVLink listening on both ports (ROV + USV)
    mavlinkManager.start(settings.rovPort(), settings.usvPort());

    // Wire joystick manager to vehicle manager and start
    joystickManager.setVehicleManager(&vehicleManager);
    joystickManager.setSettings(&settings);
    joystickManager.loadConfig();
    joystickManager.start();

    // Set up QML engine
    // Register C++ types so QML can use them as return types
    qmlRegisterUncreatableType<VideoReceiver>("RovoControl", 1, 0, "VideoReceiver", "Use videoManager.receiver()");
    qmlRegisterUncreatableType<Joystick>("RovoControl", 1, 0, "Joystick", "Use joystickManager.joystick()");

    QQmlApplicationEngine engine;

    // Expose C++ objects to QML
    engine.rootContext()->setContextProperty("settings", &settings);
    engine.rootContext()->setContextProperty("mavlinkManager", &mavlinkManager);
    engine.rootContext()->setContextProperty("vehicleManager", &vehicleManager);
    engine.rootContext()->setContextProperty("videoManager", &videoManager);
    engine.rootContext()->setContextProperty("joystickManager", &joystickManager);
    engine.rootContext()->setContextProperty("mapBridge", &mapBridge);

    // Load main QML
    const QUrl url(u"qrc:/qt/qml/RovoControl/main.qml"_qs);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() {
                         qCritical() << "QML object creation failed!";
                         QCoreApplication::exit(-1);
                     },
                     Qt::QueuedConnection);

    qDebug() << "Loading QML from:" << url;
    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML - no root objects!";
        return -1;
    }

    qDebug() << "RovoControl started successfully";
    return app.exec();
}

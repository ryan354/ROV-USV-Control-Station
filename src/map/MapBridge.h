#pragma once

#include <QObject>

class MapBridge : public QObject
{
    Q_OBJECT

public:
    explicit MapBridge(QObject *parent = nullptr);

    // Called from C++ (VehicleManager position updates)
    Q_INVOKABLE void updateVehiclePosition(int sysId, double latitude, double longitude,
                                            double heading, int vehicleType);

    // Called from C++ to control map
    Q_INVOKABLE void centerOnVehicle(int sysId);
    Q_INVOKABLE void clearTrack(int sysId);
    Q_INVOKABLE void clearAllTracks();
    Q_INVOKABLE void setZoom(int zoom);
    Q_INVOKABLE void fitAllVehicles();

signals:
    // Emitted toward JavaScript (Leaflet) via QWebChannel
    void updateMarker(int sysId, double latitude, double longitude,
                      double heading, int vehicleType);
    void centerMap(double latitude, double longitude, int zoom);
    void clearVehicleTrack(int sysId);
    void clearAll();
    void fitBounds();

    // Emitted from JavaScript toward C++
    void mapClicked(double latitude, double longitude);
    void waypointMoved(int waypointId, double latitude, double longitude);
    void mapReady();
};

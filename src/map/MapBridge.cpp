#include "MapBridge.h"
#include <QDebug>

MapBridge::MapBridge(QObject *parent)
    : QObject(parent)
{
}

void MapBridge::updateVehiclePosition(int sysId, double latitude, double longitude,
                                       double heading, int vehicleType)
{
    // Skip invalid positions
    if (latitude == 0.0 && longitude == 0.0) return;

    emit updateMarker(sysId, latitude, longitude, heading, vehicleType);
}

void MapBridge::centerOnVehicle(int sysId)
{
    Q_UNUSED(sysId)
    // Will be connected to track active vehicle position
}

void MapBridge::clearTrack(int sysId)
{
    emit clearVehicleTrack(sysId);
}

void MapBridge::clearAllTracks()
{
    emit clearAll();
}

void MapBridge::setZoom(int zoom)
{
    emit centerMap(0, 0, zoom);
}

void MapBridge::fitAllVehicles()
{
    emit fitBounds();
}

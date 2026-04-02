import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

Rectangle {
    id: root
    height: Theme.statusBarHeight
    color: Theme.bgSecondary

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMd
        anchors.rightMargin: Theme.spacingMd
        spacing: Theme.spacingLg

        // ROV connection status
        RowLayout {
            spacing: Theme.spacingXs

            Rectangle {
                width: 6; height: 6; radius: 3
                color: vehicleManager.rovVehicle && vehicleManager.rovVehicle.connected
                       ? Theme.success : Theme.danger
            }

            Label {
                text: {
                    if (vehicleManager.rovVehicle && vehicleManager.rovVehicle.connected)
                        return "ROV Connected"
                    return "ROV Disconnected"
                }
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.monoFamily
                color: Theme.textSecondary
            }
        }

        // USV connection status
        RowLayout {
            spacing: Theme.spacingXs

            Rectangle {
                width: 6; height: 6; radius: 3
                color: vehicleManager.usvVehicle && vehicleManager.usvVehicle.connected
                       ? Theme.success : Theme.danger
            }

            Label {
                text: {
                    if (vehicleManager.usvVehicle && vehicleManager.usvVehicle.connected)
                        return "USV Connected"
                    return "USV Disconnected"
                }
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.monoFamily
                color: Theme.textSecondary
            }
        }

        Rectangle { width: 1; height: 14; color: Theme.border }

        // MAVLink stats
        Label {
            text: "MAVLink: " + mavlinkManager.messagesPerSecond + " msg/s"
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.monoFamily
            color: Theme.textSecondary
        }

        Item { Layout.fillWidth: true }

        // Port info
        Label {
            text: "Port: " + mavlinkManager.port
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.monoFamily
            color: Theme.textDim
        }

        // Version
        Label {
            text: "v0.1.0"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textDim
        }
    }
}

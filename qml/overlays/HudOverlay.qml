import QtQuick
import QtQuick.Layouts
import RovoControl

Item {
    id: root

    property var vehicle: null
    property bool compact: width < 400

    visible: vehicle !== null

    // Top bar: mode + name + battery
    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingSm

        HudBadge {
            text: vehicle ? vehicle.flightMode : "---"
            color: vehicle && vehicle.armed ? Theme.danger : Theme.success
        }

        Item { width: 1; height: 1; Layout.fillWidth: true }

        HudBadge {
            text: vehicle ? vehicle.name : "---"
            color: {
                if (!vehicle) return Theme.textDim
                return vehicle.vehicleType === 1 ? Theme.rovColor : Theme.usvColor
            }
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item { width: 1; height: 1; Layout.fillWidth: true }

        HudBadge {
            text: vehicle ? vehicle.batteryVoltage.toFixed(1) + "V" : "---V"
            color: {
                if (!vehicle) return Theme.textDim
                if (vehicle.batteryPercent >= 0 && vehicle.batteryPercent < 20) return Theme.danger
                if (vehicle.batteryPercent >= 0 && vehicle.batteryPercent < 40) return Theme.warning
                return Theme.hudText
            }
        }
    }

    // Center: Attitude indicator
    AttitudeIndicator {
        anchors.centerIn: parent
        width: compact ? 100 : 150
        height: width
        roll: vehicle ? vehicle.roll : 0
        pitch: vehicle ? vehicle.pitch : 0
        visible: !compact
    }

    // Right side: Depth gauge (ROV only)
    DepthGauge {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Theme.spacingMd
        height: parent.height * 0.6
        width: 40
        visible: vehicle && vehicle.vehicleType === 1  // ROV
        depth: vehicle ? vehicle.depth : 0
        maxDepth: 100
    }

    // Bottom bar: heading + speed + depth/altitude
    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingMd

        // Compass
        CompassRose {
            width: 50
            height: 50
            heading: vehicle ? vehicle.heading : 0
        }

        // Telemetry readouts
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            HudText { text: "HDG " + (vehicle ? vehicle.heading.toFixed(0) + "°" : "---") }
            HudText { text: "SPD " + (vehicle ? vehicle.groundSpeed.toFixed(1) + " m/s" : "---") }
            HudText {
                text: {
                    if (!vehicle) return "DEP ---"
                    if (vehicle.vehicleType === 1) // ROV
                        return "DEP " + vehicle.depth.toFixed(1) + " m"
                    return "ALT " + vehicle.altitude.toFixed(1) + " m"
                }
            }
        }

        Item { width: 1; height: 1 }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            HudText { text: "THR " + (vehicle ? vehicle.throttle.toFixed(0) + "%" : "---") }
            HudText { text: "BAT " + (vehicle ? (vehicle.batteryPercent >= 0 ? vehicle.batteryPercent + "%" : "---") : "---") }
        }
    }

    // HUD text components
    component HudBadge: Rectangle {
        property alias text: label.text
        property alias color: label.color
        width: label.width + Theme.spacingSm * 2
        height: label.height + Theme.spacingXs
        radius: 4
        color: Theme.hudBg

        Label {
            id: label
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.monoFamily
            font.bold: true
            color: Theme.hudText
        }
    }

    component HudText: Label {
        font.pixelSize: 11
        font.family: Theme.monoFamily
        font.bold: true
        color: Theme.hudText
        style: Text.Outline
        styleColor: "#80000000"
    }
}

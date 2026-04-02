import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

Rectangle {
    id: root
    color: Theme.bgPanel

    property var vehicle: vehicleManager.activeVehicle

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingLg

        // Vehicle name indicator
        Rectangle {
            Layout.preferredWidth: 100
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Label {
                    text: vehicle ? vehicle.name : "---"
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    color: {
                        if (!vehicle) return Theme.textDim
                        return vehicle.vehicleType === 1 ? Theme.rovColor : Theme.usvColor
                    }
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: vehicle ? vehicle.flightMode : "---"
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.monoFamily
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 18
                    radius: 9
                    color: vehicle && vehicle.armed ? Theme.danger : Theme.success
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        anchors.centerIn: parent
                        text: vehicle && vehicle.armed ? "ARMED" : "DISARMED"
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.textBright
                    }
                }
            }
        }

        Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 4; Layout.bottomMargin: 4; color: Theme.border }

        // Telemetry values grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 6
            columnSpacing: Theme.spacingLg
            rowSpacing: 2

            // Row 1: Labels
            TelemetryLabel { text: "DEPTH" }
            TelemetryLabel { text: "HEADING" }
            TelemetryLabel { text: "SPEED" }
            TelemetryLabel { text: "BATTERY" }
            TelemetryLabel { text: "GPS" }
            TelemetryLabel { text: "THROTTLE" }

            // Row 2: Values
            TelemetryValue { text: vehicle ? vehicle.depth.toFixed(1) + " m" : "--- m" }
            TelemetryValue { text: vehicle ? vehicle.heading.toFixed(0) + "°" : "---°" }
            TelemetryValue { text: vehicle ? vehicle.groundSpeed.toFixed(1) + " m/s" : "--- m/s" }
            TelemetryValue {
                text: vehicle ? vehicle.batteryVoltage.toFixed(1) + "V " +
                      (vehicle.batteryPercent >= 0 ? vehicle.batteryPercent + "%" : "") : "---V"
                color: {
                    if (!vehicle) return Theme.hudText
                    if (vehicle.batteryPercent >= 0 && vehicle.batteryPercent < 20) return Theme.danger
                    if (vehicle.batteryPercent >= 0 && vehicle.batteryPercent < 40) return Theme.warning
                    return Theme.hudText
                }
            }
            TelemetryValue {
                text: vehicle ? vehicle.gpsSatCount + " sats" : "--- sats"
                color: {
                    if (!vehicle) return Theme.hudText
                    if (vehicle.gpsFixType < 2) return Theme.danger
                    if (vehicle.gpsFixType < 3) return Theme.warning
                    return Theme.hudText
                }
            }
            TelemetryValue { text: vehicle ? vehicle.throttle.toFixed(0) + "%" : "---%"}

            // Row 3: Secondary labels
            TelemetryLabel { text: "ROLL" }
            TelemetryLabel { text: "PITCH" }
            TelemetryLabel { text: "YAW" }
            TelemetryLabel { text: "CURRENT" }
            TelemetryLabel { text: "ALT" }
            TelemetryLabel { text: "CLIMB" }

            // Row 4: Secondary values
            TelemetryValue { text: vehicle ? vehicle.roll.toFixed(1) + "°" : "---°" }
            TelemetryValue { text: vehicle ? vehicle.pitch.toFixed(1) + "°" : "---°" }
            TelemetryValue { text: vehicle ? vehicle.yaw.toFixed(1) + "°" : "---°" }
            TelemetryValue { text: vehicle ? vehicle.batteryCurrent.toFixed(1) + " A" : "--- A" }
            TelemetryValue { text: vehicle ? vehicle.altitude.toFixed(1) + " m" : "--- m" }
            TelemetryValue { text: vehicle ? vehicle.climbRate.toFixed(1) + " m/s" : "--- m/s" }
        }
    }

    // Telemetry label component
    component TelemetryLabel: Label {
        font.pixelSize: 9
        font.family: Theme.monoFamily
        font.capitalization: Font.AllUppercase
        color: Theme.textDim
    }

    // Telemetry value component
    component TelemetryValue: Label {
        font.pixelSize: Theme.fontSizeHud
        font.family: Theme.monoFamily
        font.bold: true
        color: Theme.hudText
    }
}

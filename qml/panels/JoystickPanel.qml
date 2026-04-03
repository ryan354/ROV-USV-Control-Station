import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

Rectangle {
    id: root
    color: Theme.bgPanel
    radius: Theme.borderRadius

    property var joystick: joystickManager.joystickCount > 0 ? joystickManager.joystick(0) : null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingSm

        Label {
            text: "JOYSTICK"
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            font.capitalization: Font.AllUppercase
            color: Theme.textSecondary
        }

        Label {
            text: joystick ? joystick.name : "No joystick connected"
            font.pixelSize: Theme.fontSizeSmall
            color: joystick ? Theme.textPrimary : Theme.textDim
        }

        // Axis visualization
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.spacingSm
            rowSpacing: Theme.spacingXs
            visible: joystick !== null

            Label { text: "X (Lat)"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
            AxisBar { value: joystick ? joystick.axisX : 0 }

            Label { text: "Y (Fwd)"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
            AxisBar { value: joystick ? joystick.axisY : 0 }

            Label { text: "Z (Thr)"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
            AxisBar { value: joystick ? joystick.axisZ : 0 }

            Label { text: "R (Yaw)"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
            AxisBar { value: joystick ? joystick.axisR : 0 }
        }

        // Deadzone slider
        RowLayout {
            visible: joystick !== null
            spacing: Theme.spacingSm

            Label {
                text: "Deadzone"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
            }

            Slider {
                Layout.fillWidth: true
                from: 0; to: 0.3; stepSize: 0.01
                value: joystick ? joystick.deadzone : 0.05
                onMoved: { if (joystick) joystick.deadzone = value }
            }

            Label {
                text: joystick ? (joystick.deadzone * 100).toFixed(0) + "%" : "5%"
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.monoFamily
                color: Theme.textSecondary
                Layout.preferredWidth: 30
            }
        }

        // Button press indicator
        RowLayout {
            visible: joystick !== null
            spacing: Theme.spacingXs

            Label {
                text: "Pressed:"
                font.pixelSize: 10
                color: Theme.textDim
            }

            Label {
                property int mask: joystick ? joystick.pressedButtonsMask : 0
                text: {
                    if (mask === 0) return "---"
                    var btns = []
                    for (var i = 0; i < 16; i++) {
                        if (mask & (1 << i)) btns.push(i)
                    }
                    return btns.join(", ")
                }
                font.pixelSize: 12
                font.bold: true
                font.family: Theme.monoFamily
                color: mask !== 0 ? Theme.secondary : Theme.textDim
            }
        }

        // Button grid
        Flow {
            Layout.fillWidth: true
            spacing: 3
            visible: joystick !== null

            Repeater {
                model: joystick ? Math.min(joystick.buttonCount, 16) : 0
                Rectangle {
                    width: 24; height: 18
                    radius: 3
                    color: joystick && (joystick.pressedButtonsMask & (1 << index)) ? Theme.secondary : Theme.bgInput
                    border.width: 1
                    border.color: joystick && (joystick.pressedButtonsMask & (1 << index)) ? Theme.secondary : Theme.border

                    Label {
                        anchors.centerIn: parent
                        text: index
                        font.pixelSize: 8
                        font.family: Theme.monoFamily
                        font.bold: joystick && (joystick.pressedButtonsMask & (1 << index))
                        color: joystick && (joystick.pressedButtonsMask & (1 << index)) ? Theme.bgPrimary : Theme.textDim
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // Axis bar component
    component AxisBar: Rectangle {
        property real value: 0
        Layout.fillWidth: true
        height: 12
        color: Theme.bgInput
        radius: 3

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 + (value * parent.width / 2) - 2
            width: 4
            height: parent.height
            radius: 2
            color: Theme.secondary
        }

        // Center line
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - 2
            color: Theme.textDim
        }
    }
}

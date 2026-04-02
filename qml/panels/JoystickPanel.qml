import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

Rectangle {
    id: root
    color: Theme.bgPanel
    radius: Theme.borderRadius

    property var joystick: joystickManager.activeJoystick

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

            Label { text: "X"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
            AxisBar { value: joystick ? joystick.axisX : 0 }

            Label { text: "Y"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
            AxisBar { value: joystick ? joystick.axisY : 0 }

            Label { text: "Z"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
            AxisBar { value: joystick ? joystick.axisZ : 0 }

            Label { text: "R"; font.pixelSize: 10; font.family: Theme.monoFamily; color: Theme.textDim }
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

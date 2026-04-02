import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

RowLayout {
    id: root
    spacing: Theme.spacingSm

    property var vehicle: vehicleManager.activeVehicle

    // Arm button
    Button {
        id: armBtn
        text: "ARM"
        enabled: vehicle !== null && vehicle.connected && !vehicle.armed

        background: Rectangle {
            color: armBtn.enabled ?
                   (armBtn.pressed ? Qt.darker(Theme.danger, 1.3) :
                    armBtn.hovered ? Qt.lighter(Theme.danger, 1.1) : Theme.danger)
                   : Theme.bgInput
            radius: Theme.borderRadius
        }

        contentItem: Label {
            text: parent.text
            color: armBtn.enabled ? Theme.textBright : Theme.textDim
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        onClicked: armConfirm.open()
    }

    // Disarm button
    Button {
        id: disarmBtn
        text: "DISARM"
        enabled: vehicle !== null && vehicle.connected && vehicle.armed

        background: Rectangle {
            color: disarmBtn.enabled ?
                   (disarmBtn.pressed ? Qt.darker(Theme.success, 1.3) :
                    disarmBtn.hovered ? Qt.lighter(Theme.success, 1.1) : Theme.success)
                   : Theme.bgInput
            radius: Theme.borderRadius
        }

        contentItem: Label {
            text: parent.text
            color: disarmBtn.enabled ? Theme.textBright : Theme.textDim
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        onClicked: vehicle.disarm()
    }

    Rectangle { width: 1; height: 24; color: Theme.border }

    // Mode selector
    Label {
        text: "Mode:"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.textSecondary
    }

    ComboBox {
        id: modeCombo
        width: 120
        model: {
            if (!vehicle) return []
            // vehicleType: 1=ROV, 2=USV
            if (vehicle.vehicleType === 1) {
                return ["MANUAL", "STABILIZE", "ALT_HOLD", "POSHOLD", "GUIDED", "AUTO", "SURFACE"]
            } else {
                return ["MANUAL", "HOLD", "LOITER", "AUTO", "RTL", "GUIDED", "ACRO"]
            }
        }

        currentIndex: {
            if (!vehicle) return -1
            var idx = model.indexOf(vehicle.flightMode)
            return idx >= 0 ? idx : -1
        }

        onActivated: {
            if (vehicle && currentText) {
                vehicle.setMode(currentText)
            }
        }

        background: Rectangle {
            color: Theme.bgInput
            radius: Theme.borderRadius
            border.width: 1
            border.color: Theme.border
        }

        contentItem: Label {
            text: modeCombo.displayText
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.monoFamily
            verticalAlignment: Text.AlignVCenter
            leftPadding: Theme.spacingSm
        }
    }

    // Arm confirmation dialog
    ConfirmDialog {
        id: armConfirm
        title: "Arm Vehicle"
        message: vehicle ? "Are you sure you want to ARM " + vehicle.name + "?" : ""
        confirmText: "ARM"
        confirmColor: Theme.danger
        onConfirmed: {
            if (vehicle) vehicle.arm()
        }
    }
}

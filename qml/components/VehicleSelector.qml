import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

RowLayout {
    id: root
    spacing: Theme.spacingXs

    // ROV button
    Button {
        id: rovBtn
        text: vehicleManager.rovVehicle ? vehicleManager.rovVehicle.name : "ROV"
        flat: true
        highlighted: vehicleManager.activeVehicle === vehicleManager.rovVehicle
        enabled: vehicleManager.rovVehicle !== null

        contentItem: RowLayout {
            spacing: Theme.spacingXs

            Rectangle {
                width: 8; height: 8; radius: 4
                color: vehicleManager.rovVehicle && vehicleManager.rovVehicle.connected
                       ? Theme.success : Theme.textDim
            }

            Label {
                text: rovBtn.text
                font.pixelSize: Theme.fontSizeNormal
                font.bold: rovBtn.highlighted
                color: rovBtn.highlighted ? Theme.rovColor : Theme.textSecondary
            }
        }

        background: Rectangle {
            color: rovBtn.highlighted ? Qt.rgba(0, 0.74, 0.83, 0.15) : // rovColor with alpha
                   rovBtn.hovered ? Theme.bgHover : "transparent"
            radius: Theme.borderRadius
            border.width: rovBtn.highlighted ? 1 : 0
            border.color: Theme.rovColor
        }

        onClicked: vehicleManager.selectROV()
    }

    // Separator
    Rectangle { width: 1; height: 24; color: Theme.border }

    // USV button
    Button {
        id: usvBtn
        text: vehicleManager.usvVehicle ? vehicleManager.usvVehicle.name : "USV"
        flat: true
        highlighted: vehicleManager.activeVehicle === vehicleManager.usvVehicle
        enabled: vehicleManager.usvVehicle !== null

        contentItem: RowLayout {
            spacing: Theme.spacingXs

            Rectangle {
                width: 8; height: 8; radius: 4
                color: vehicleManager.usvVehicle && vehicleManager.usvVehicle.connected
                       ? Theme.success : Theme.textDim
            }

            Label {
                text: usvBtn.text
                font.pixelSize: Theme.fontSizeNormal
                font.bold: usvBtn.highlighted
                color: usvBtn.highlighted ? Theme.usvColor : Theme.textSecondary
            }
        }

        background: Rectangle {
            color: usvBtn.highlighted ? Qt.rgba(1, 0.6, 0, 0.15) : // usvColor with alpha
                   usvBtn.hovered ? Theme.bgHover : "transparent"
            radius: Theme.borderRadius
            border.width: usvBtn.highlighted ? 1 : 0
            border.color: Theme.usvColor
        }

        onClicked: vehicleManager.selectUSV()
    }
}

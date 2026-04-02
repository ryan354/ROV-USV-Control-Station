import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

Rectangle {
    id: root
    color: Theme.bgPrimary
    clip: true

    property int maximizedIndex: -1

    Grid {
        anchors.fill: parent
        anchors.margins: 1
        columns: maximizedIndex >= 0 ? 1 : 2
        rows: maximizedIndex >= 0 ? 1 : 2
        spacing: 2

        Repeater {
            model: 4

            VideoPanel {
                id: videoPanel
                width: maximizedIndex >= 0
                       ? (maximizedIndex === index ? root.width - 2 : 0)
                       : (root.width - 4) / 2
                height: maximizedIndex >= 0
                        ? (maximizedIndex === index ? root.height - 2 : 0)
                        : (root.height - 4) / 2
                visible: maximizedIndex < 0 || maximizedIndex === index

                streamIndex: index
                label: {
                    switch(index) {
                    case 0: return vehicleManager.rovVehicle ? vehicleManager.rovVehicle.name + " Cam 1" : "ROV Cam 1"
                    case 1: return vehicleManager.rovVehicle ? vehicleManager.rovVehicle.name + " Cam 2" : "ROV Cam 2"
                    case 2: return vehicleManager.usvVehicle ? vehicleManager.usvVehicle.name + " Cam 1" : "USV Cam 1"
                    case 3: return vehicleManager.usvVehicle ? vehicleManager.usvVehicle.name + " Cam 2" : "USV Cam 2"
                    default: return "Camera " + (index + 1)
                    }
                }
                showHud: index === 0 || index === 2  // HUD on primary cameras
                maximized: maximizedIndex === index

                onRequestMaximize: root.maximizedIndex = index
                onRequestMinimize: root.maximizedIndex = -1

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
            }
        }
    }

    // Grid controls overlay
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingXs

        Button {
            visible: root.maximizedIndex >= 0
            text: "Grid View"
            flat: true
            font.pixelSize: Theme.fontSizeSmall
            onClicked: root.maximizedIndex = -1

            background: Rectangle {
                color: Theme.hudBg
                radius: Theme.borderRadius
            }

            contentItem: Label {
                text: parent.text
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}

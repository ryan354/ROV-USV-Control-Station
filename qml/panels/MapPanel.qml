import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import QtWebChannel
import RovoControl

Rectangle {
    id: root
    color: Theme.bgPanel
    clip: true

    // QWebChannel for C++ <-> JS communication
    WebChannel {
        id: webChannel
        registeredObjects: [mapBridge]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Map header bar
        Rectangle {
            Layout.fillWidth: true
            height: Theme.panelHeaderHeight
            color: Theme.bgTertiary

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSm
                anchors.rightMargin: Theme.spacingXs
                spacing: Theme.spacingXs

                Label {
                    text: "MAP"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                ToolButton {
                    text: "Fit All"
                    font.pixelSize: Theme.fontSizeSmall
                    onClicked: mapBridge.fitAllVehicles()

                    background: Rectangle {
                        color: parent.hovered ? Theme.bgHover : "transparent"
                        radius: 4
                    }
                    contentItem: Label {
                        text: parent.text
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                ToolButton {
                    text: "Clear"
                    font.pixelSize: Theme.fontSizeSmall
                    onClicked: mapBridge.clearAllTracks()

                    background: Rectangle {
                        color: parent.hovered ? Theme.bgHover : "transparent"
                        radius: 4
                    }
                    contentItem: Label {
                        text: parent.text
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }

        // Leaflet map via WebEngine
        WebEngineView {
            id: mapView
            Layout.fillWidth: true
            Layout.fillHeight: true
            url: "qrc:/map/index.html"
            webChannel: webChannel

            backgroundColor: Theme.bgPrimary

            // Disable context menu
            onContextMenuRequested: function(request) {
                request.accepted = true
            }
        }
    }

    // Coordinates display overlay
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Theme.spacingSm
        color: Theme.hudBg
        radius: 4
        padding: Theme.spacingXs
        width: coordLabel.width + Theme.spacingSm * 2
        height: coordLabel.height + Theme.spacingXs * 2

        Label {
            id: coordLabel
            anchors.centerIn: parent
            text: {
                var v = vehicleManager.activeVehicle
                if (!v) return "No vehicle"
                return v.name + ": " + v.latitude.toFixed(6) + ", " + v.longitude.toFixed(6)
            }
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.monoFamily
            color: Theme.hudText
        }
    }
}

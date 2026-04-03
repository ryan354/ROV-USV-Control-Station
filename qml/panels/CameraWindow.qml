import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

Window {
    id: camWindow
    title: "RovoControl — Camera Feeds"
    width: 960
    height: 540
    minimumWidth: 640
    minimumHeight: 360
    color: "#0a0f0a"
    visible: true

    property var rov: null
    property var usv: null

    // ── Header ──
    Rectangle {
        id: camHeader
        anchors.top: parent.top
        width: parent.width
        height: 32
        color: "#0f1a0f"
        z: 1

        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1a3a1a" }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
            Label { text: "CAMERA FEEDS"; font.pixelSize: 12; font.bold: true; color: "#ff2020" }
            Item { Layout.fillWidth: true }
            Label {
                text: "ROV: " + (rov && rov.connected ? "Online" : "Offline")
                font.pixelSize: 10; color: rov && rov.connected ? "#00ccff" : "#2a5a2a"
            }
            Rectangle { width: 1; height: 14; color: "#1a3a1a" }
            Label {
                text: "USV: " + (usv && usv.connected ? "Online" : "Offline")
                font.pixelSize: 10; color: usv && usv.connected ? "#ffaa00" : "#2a5a2a"
            }
        }
    }

    // ── Video Grid ──
    Rectangle {
        anchors.top: camHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#0a0f0a"

        Grid {
            id: videoGrid
            anchors.fill: parent; anchors.margins: 2
            columns: 2; rows: 2; spacing: 2

            Repeater {
                model: [
                    { name: "ROV Cam 1", col: "#00ccff", vtype: "rov" },
                    { name: "ROV Cam 2", col: "#00ccff", vtype: "rov" },
                    { name: "USV Cam 1", col: "#ffaa00", vtype: "usv" },
                    { name: "USV Cam 2", col: "#ffaa00", vtype: "usv" }
                ]

                Rectangle {
                    width: (videoGrid.width - 6) / 2
                    height: (videoGrid.height - 6) / 2
                    color: "#0f1a0f"
                    border.width: 1; border.color: "#1a3a1a"

                    property var cam_vehicle: modelData.vtype === "rov" ? camWindow.rov : camWindow.usv

                    Column {
                        anchors.centerIn: parent; spacing: 8
                        Label {
                            text: "NO SIGNAL"
                            font.pixelSize: 16; font.bold: true; color: "#2a5a2a"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: cam_vehicle ? cam_vehicle.name + " Cam" : modelData.name
                            font.pixelSize: 11; color: "#44aa44"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Label badge
                    Rectangle {
                        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 8
                        color: "#80000000"; radius: 4
                        width: camBadgeLbl.width + 12; height: camBadgeLbl.height + 4
                        Label {
                            id: camBadgeLbl; anchors.centerIn: parent
                            text: cam_vehicle ? cam_vehicle.name + " Cam " + ((index % 2) + 1) : modelData.name
                            font.pixelSize: 10; color: modelData.col
                        }
                    }
                }
            }
        }
    }
}

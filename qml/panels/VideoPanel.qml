import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import RovoControl

Rectangle {
    id: root
    color: Theme.bgPrimary
    clip: true

    property int streamIndex: 0
    property string label: "Camera " + (streamIndex + 1)
    property bool showHud: true
    property bool maximized: false

    signal requestMaximize()
    signal requestMinimize()

    // Video output
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit

        VideoSurface {
            id: videoSurface
            streamIndex: root.streamIndex
            videoSink: videoOutput.videoSink
        }
    }

    // No-signal placeholder
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        visible: !videoManager.receiver(root.streamIndex) ||
                 !videoManager.receiver(root.streamIndex).playing

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingSm

            Label {
                text: "NO SIGNAL"
                font.pixelSize: Theme.fontSizeLarge
                font.family: Theme.monoFamily
                font.bold: true
                color: Theme.textDim
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: root.label
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textDim
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Camera label overlay
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Theme.spacingSm
        color: Theme.hudBg
        radius: 4
        padding: Theme.spacingXs
        width: labelText.width + Theme.spacingSm * 2
        height: labelText.height + Theme.spacingXs * 2

        Label {
            id: labelText
            anchors.centerIn: parent
            text: root.label
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.monoFamily
            color: Theme.hudText
        }
    }

    // HUD Overlay
    HudOverlay {
        anchors.fill: parent
        visible: root.showHud && vehicleManager.activeVehicle !== null
        vehicle: vehicleManager.activeVehicle
    }

    // Click to maximize/minimize
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: {
            if (root.maximized) {
                root.requestMinimize()
            } else {
                root.requestMaximize()
            }
        }
    }

    // Border
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Theme.border
    }
}

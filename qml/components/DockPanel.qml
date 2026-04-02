import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RovoControl

Rectangle {
    id: root
    color: Theme.bgPanel
    radius: Theme.borderRadius
    border.width: Theme.borderWidth
    border.color: Theme.border

    property string title: "Panel"
    property bool collapsible: true
    property bool collapsed: false
    property alias content: contentArea.children

    default property alias panelContent: contentArea.children

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: Theme.panelHeaderHeight
            color: Theme.bgTertiary
            radius: Theme.borderRadius

            // Bottom corners not rounded when panel is expanded
            Rectangle {
                visible: !root.collapsed
                anchors.bottom: parent.bottom
                width: parent.width
                height: Theme.borderRadius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSm
                anchors.rightMargin: Theme.spacingXs
                spacing: Theme.spacingXs

                Label {
                    text: root.title
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                }

                ToolButton {
                    visible: root.collapsible
                    width: 24; height: 24
                    text: root.collapsed ? "+" : "-"
                    font.pixelSize: 14
                    font.bold: true
                    onClicked: root.collapsed = !root.collapsed

                    contentItem: Label {
                        text: parent.text
                        color: Theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.hovered ? Theme.bgHover : "transparent"
                        radius: 4
                    }
                }
            }
        }

        // Content area
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.collapsed
            clip: true
        }
    }
}

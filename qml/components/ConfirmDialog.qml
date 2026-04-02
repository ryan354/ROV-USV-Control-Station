import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import RovoControl

Dialog {
    id: root
    anchors.centerIn: parent
    modal: true
    width: 360

    property string message: ""
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property color confirmColor: Theme.accent

    signal confirmed()

    Material.background: Theme.bgPanel

    contentItem: ColumnLayout {
        spacing: Theme.spacingLg

        Label {
            text: root.message
            font.pixelSize: Theme.fontSizeNormal
            color: Theme.textPrimary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Theme.spacingSm

            Button {
                text: root.cancelText
                flat: true
                onClicked: root.close()

                contentItem: Label {
                    text: parent.text
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Button {
                text: root.confirmText
                onClicked: {
                    root.confirmed()
                    root.close()
                }

                background: Rectangle {
                    color: parent.pressed ? Qt.darker(root.confirmColor, 1.2) :
                           parent.hovered ? Qt.lighter(root.confirmColor, 1.1) :
                           root.confirmColor
                    radius: Theme.borderRadius
                }

                contentItem: Label {
                    text: parent.text
                    color: Theme.textBright
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config

// Read-only monospace snippet with a copy button (uses wl-copy).
Rectangle {
    id: root

    property string title: ""
    property string code: ""

    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + 24
    radius: 10
    color: Qt.rgba(0, 0, 0, 0.28)
    border.width: 1
    border.color: Theme.hairline

    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.textDim
                font.family: Theme.fontSans
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            PillButton {
                implicitHeight: 26
                text: copied.running ? "Copied" : "Copy"
                icon: copied.running ? "check" : "content_copy"
                onClicked: {
                    Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", root.code]);
                    copied.restart();
                }
                Timer { id: copied; interval: 1400 }
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.code
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: 11
            wrapMode: Text.WrapAnywhere
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.config

// Quick-settings tile: icon, title, status line. Glows when active.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool enabledTile: true
    signal clicked()
    signal rightClicked()

    implicitHeight: 60
    radius: Theme.radiusSm + 2
    opacity: enabledTile ? 1 : 0.45
    color: active ? Theme.alpha(Theme.accent, 0.16) : (ma.containsMouse ? Theme.tileHover : Theme.tile)
    border.width: 1
    border.color: active ? Theme.alpha(Theme.accent, 0.55) : Theme.hairline
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animMed } }
    scale: ma.pressed ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: root.active ? Theme.alpha(Theme.accent, 0.28) : Qt.rgba(1, 1, 1, 0.06)
            Behavior on color { ColorAnimation { duration: Theme.animMed } }
            Icon {
                anchors.centerIn: parent
                name: root.icon
                size: 18
                color: root.active ? Theme.accent : Theme.textDim
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: root.active ? Theme.accent : Theme.textMute
                font.family: Theme.fontSans
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => { if (!root.enabledTile) return; if (m.button === Qt.RightButton) root.rightClicked(); else root.clicked(); }
    }
}

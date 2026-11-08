import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool active: false
    property bool danger: false
    signal clicked()

    implicitHeight: 32
    implicitWidth: rowL.implicitWidth + 24
    radius: 10
    color: active ? Theme.alpha(Theme.accent, 0.22) : (ma.containsMouse ? Theme.tileHover : Qt.rgba(1, 1, 1, 0.06))
    border.width: 1
    border.color: active ? Theme.alpha(Theme.accent, 0.6) : Theme.hairline
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    scale: ma.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    RowLayout {
        id: rowL
        anchors.centerIn: parent
        spacing: 6
        Icon { visible: root.icon !== ""; name: root.icon; size: 15; color: root.danger ? Theme.bad : (root.active ? Theme.accent : Theme.textDim) }
        Text {
            visible: root.text !== ""
            text: root.text
            color: root.danger ? Theme.bad : (root.active ? Theme.text : Theme.textDim)
            font.family: Theme.fontSans
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

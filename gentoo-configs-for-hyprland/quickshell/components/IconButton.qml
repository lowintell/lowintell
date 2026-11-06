import QtQuick
import qs.config

Item {
    id: root

    property string icon: ""
    property int size: 36
    property int iconSize: 18
    property bool active: false
    property color iconColor: active ? Theme.accent : Theme.text
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    scale: ma.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.active ? Theme.alpha(Theme.accent, 0.18) : (ma.containsMouse ? Theme.tileHover : "transparent")
        border.width: root.active ? 1 : 0
        border.color: Theme.alpha(Theme.accent, 0.5)
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.iconColor
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

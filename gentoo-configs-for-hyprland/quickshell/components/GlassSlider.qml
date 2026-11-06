import QtQuick
import qs.config

// Smooth slider with a gradient fill and glowing handle. Emits moved(v) with v in 0..1.
Item {
    id: root

    property real value: 0
    property color tint: Theme.accent
    readonly property bool dragging: ma.pressed
    signal moved(real v)

    implicitWidth: 200
    implicitHeight: 26

    property real shown: value
    Behavior on shown { enabled: !root.dragging; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        id: track
        width: parent.width
        height: 6
        radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(1, 1, 1, 0.09)

        Rectangle {
            width: Math.max(parent.height, handle.x + handle.width / 2)
            height: parent.height
            radius: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(root.tint, 0.55) }
                GradientStop { position: 1.0; color: Theme.accent2 }
            }
        }
    }

    Rectangle {
        id: handle
        width: 16
        height: 16
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(1, root.shown)) * (root.width - width)
        color: Theme.text
        scale: ma.pressed ? 1.18 : (ma.containsMouse ? 1.08 : 1)
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        Rectangle {
            z: -1
            anchors.centerIn: parent
            width: parent.width + 10
            height: width
            radius: width / 2
            color: Theme.alpha(root.tint, ma.pressed ? 0.35 : 0.2)
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            root.moved(Math.max(0, Math.min(1, (mx - handle.width / 2) / (root.width - handle.width))));
        }
        onPressed: m => update(m.x)
        onPositionChanged: m => { if (pressed) update(m.x); }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
    }
}

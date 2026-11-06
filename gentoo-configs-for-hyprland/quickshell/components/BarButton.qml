import QtQuick
import QtQuick.Layouts
import qs.config

// Pill-shaped hover target used inside the top bar. Children are laid out in a row.
Rectangle {
    id: root

    property bool active: false
    default property alias content: row.data
    property alias spacing: row.spacing
    signal clicked(var mouse)
    signal scrolled(int delta)

    implicitHeight: 26
    implicitWidth: row.implicitWidth + 16
    radius: 9
    color: active ? Theme.alpha(Theme.accent, 0.20) : (ma.containsMouse ? Theme.tileHover : "transparent")
    border.width: active ? 1 : 0
    border.color: Theme.alpha(Theme.accent, 0.5)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        onWheel: w => root.scrolled(w.angleDelta.y)
    }
}

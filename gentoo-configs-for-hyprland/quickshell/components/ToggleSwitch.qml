import QtQuick
import qs.config

Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 42
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.alpha(Theme.accent, 0.40) : Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
        border.color: root.checked ? Theme.alpha(Theme.accent, 0.75) : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.text : Theme.textDim
            Behavior on x { NumberAnimation { duration: Theme.animFast + 40; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}

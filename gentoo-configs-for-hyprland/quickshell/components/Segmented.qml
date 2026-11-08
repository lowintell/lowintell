import QtQuick
import qs.config

// Pill-style single choice. options: [{ value, label }]
Rectangle {
    id: root

    property var options: []
    property var current
    signal picked(var value)

    implicitHeight: 32
    implicitWidth: row.implicitWidth + 6
    radius: 10
    color: Qt.rgba(1, 1, 1, 0.06)
    border.width: 1
    border.color: Theme.hairline

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options
            delegate: Rectangle {
                id: opt
                required property var modelData
                readonly property bool on: root.current === modelData.value
                height: 26
                width: lbl.implicitWidth + 22
                radius: 8
                color: on ? Theme.alpha(Theme.accent, 0.26) : (ma.containsMouse ? Theme.tileHover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: opt.modelData.label
                    color: opt.on ? Theme.text : Theme.textDim
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(opt.modelData.value)
                }
            }
        }
    }
}

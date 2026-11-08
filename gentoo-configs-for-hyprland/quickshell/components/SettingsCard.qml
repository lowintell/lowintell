import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string title: ""
    default property alias content: inner.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 28
    radius: Theme.radiusSm + 2
    color: Theme.tile
    border.width: 1
    border.color: Theme.hairline

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 12

        Text {
            visible: root.title !== ""
            text: root.title
            color: Theme.accent
            font.family: Theme.fontSans
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.2
        }
        ColumnLayout {
            id: inner
            Layout.fillWidth: true
            spacing: 12
        }
    }
}

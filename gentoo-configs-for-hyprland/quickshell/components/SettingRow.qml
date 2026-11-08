import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string label: ""
    property string desc: ""
    default property alias control: right.data

    Layout.fillWidth: true
    spacing: 12

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
            text: root.label
            color: Theme.text
            font.family: Theme.fontSans
            font.pixelSize: 13
        }
        Text {
            Layout.fillWidth: true
            visible: root.desc !== ""
            text: root.desc
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }
    RowLayout {
        id: right
        Layout.alignment: Qt.AlignVCenter
        spacing: 8
    }
}

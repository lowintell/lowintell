import QtQuick
import qs.config

// Single-line text field. `committed` fires on Enter or when focus leaves the field.
Rectangle {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool mono: false
    property alias currentText: input.text
    signal committed(string text)

    implicitHeight: 32
    implicitWidth: 200
    radius: 9
    color: Qt.rgba(1, 1, 1, 0.06)
    border.width: 1
    border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.75) : Theme.hairline
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        verticalAlignment: Text.AlignVCenter
        color: Theme.text
        selectionColor: Theme.alpha(Theme.accent, 0.4)
        selectedTextColor: Theme.text
        font.family: root.mono ? Theme.fontMono : Theme.fontSans
        font.pixelSize: 12
        clip: true
        onEditingFinished: root.committed(text)
    }

    Text {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        color: Theme.textMute
        font.family: Theme.fontSans
        font.pixelSize: 12
    }

    onValueChanged: if (!input.activeFocus) input.text = root.value
    Component.onCompleted: input.text = root.value
}

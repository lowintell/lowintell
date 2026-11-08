import QtQuick
import QtQuick.Layouts
import qs.config

// HSV colour picker: saturation/value square, hue strip and a hex field.
ColumnLayout {
    id: root

    property color value: "#ffffff"
    signal picked(string hex)

    property real h: 0
    property real s: 0
    property real v: 1

    spacing: 10

    function sync(c) {
        const hh = c.hsvHue;
        if (hh >= 0 && c.hsvSaturation > 0.001) h = hh;
        s = c.hsvSaturation;
        v = c.hsvValue;
    }
    function emitColor() { picked(Qt.hsva(h, s, v, 1).toString()); }

    onValueChanged: if (!svMa.pressed && !hueMa.pressed) sync(value)
    Component.onCompleted: sync(value)

    Rectangle {
        id: sv
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        radius: 10
        color: Qt.hsva(root.h, 1, 1, 1)

        Rectangle {
            anchors.fill: parent
            radius: 10
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: 10
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#000000" }
            }
        }
        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: "transparent"
            border.width: 2
            border.color: "#ffffff"
            x: root.s * sv.width - 8
            y: (1 - root.v) * sv.height - 8
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: "#80000000"
            }
        }
        MouseArea {
            id: svMa
            anchors.fill: parent
            function upd(m) {
                root.s = Math.max(0, Math.min(1, m.x / width));
                root.v = 1 - Math.max(0, Math.min(1, m.y / height));
                root.emitColor();
            }
            onPressed: m => upd(m)
            onPositionChanged: m => { if (pressed) upd(m); }
        }
    }

    Rectangle {
        id: hue
        Layout.fillWidth: true
        Layout.preferredHeight: 14
        radius: 7
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#ff0000" }
            GradientStop { position: 0.1667; color: "#ffff00" }
            GradientStop { position: 0.3333; color: "#00ff00" }
            GradientStop { position: 0.5; color: "#00ffff" }
            GradientStop { position: 0.6667; color: "#0000ff" }
            GradientStop { position: 0.8333; color: "#ff00ff" }
            GradientStop { position: 1.0; color: "#ff0000" }
        }
        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: -2
            x: root.h * hue.width - 9
            color: Qt.hsva(root.h, 1, 1, 1)
            border.width: 2
            border.color: "#ffffff"
        }
        MouseArea {
            id: hueMa
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            function upd(m) {
                root.h = Math.max(0, Math.min(0.999, m.x / width));
                root.emitColor();
            }
            onPressed: m => upd(m)
            onPositionChanged: m => { if (pressed) upd(m); }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 9
            color: root.value
            border.width: 1
            border.color: Theme.hairline
        }
        FieldInput {
            Layout.preferredWidth: 120
            mono: true
            value: root.value.toString()
            onCommitted: t => {
                const m = /^#?([0-9a-fA-F]{6})$/.exec(t.trim());
                if (m) root.picked("#" + m[1].toLowerCase());
            }
        }
        Text {
            text: "hex, e.g. #a5b0ff"
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 11
        }
    }
}

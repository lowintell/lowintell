import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string label: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property real step: 0
    property real displayScale: 1
    property int decimals: 0
    property string suffix: ""
    signal moved(real v)

    Layout.fillWidth: true
    spacing: 12

    Text {
        Layout.preferredWidth: 130
        text: root.label
        color: Theme.text
        font.family: Theme.fontSans
        font.pixelSize: 13
    }
    GlassSlider {
        Layout.fillWidth: true
        value: root.to > root.from ? (root.value - root.from) / (root.to - root.from) : 0
        onMoved: v => {
            let x = root.from + v * (root.to - root.from);
            if (root.step > 0) x = Math.round(x / root.step) * root.step;
            root.moved(Math.max(root.from, Math.min(root.to, x)));
        }
    }
    Text {
        Layout.preferredWidth: 64
        horizontalAlignment: Text.AlignRight
        text: (root.value * root.displayScale).toFixed(root.decimals) + root.suffix
        color: Theme.textDim
        font.family: Theme.fontMono
        font.pixelSize: 12
    }
}

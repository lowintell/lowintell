import QtQuick
import qs.config
import qs.services

// Audio bars driven by real cava spectrum data. If cava isn't installed/running, bars fall back
// to a gentle procedural animation so the widget still reads as "playing".
Item {
    id: root

    property int bars: 16
    property bool playing: MediaService.isPlaying
    property real gap: 3
    property var fake: []

    implicitWidth: 80
    implicitHeight: 24

    Timer {
        running: root.playing && !CavaService.active && root.visible
        interval: 110
        repeat: true
        onTriggered: {
            const a = [];
            for (let i = 0; i < root.bars; i++) a.push(18 + Math.random() * 70);
            root.fake = a;
        }
    }

    function level(i) {
        if (!playing) return 6;
        const src = CavaService.active ? CavaService.values : fake;
        if (src.length === 0) return 6;
        return Math.max(6, Math.min(100, src[Math.floor(i * src.length / bars)] || 0));
    }

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.bars
            Rectangle {
                required property int index
                readonly property real bw: (root.width - (root.bars - 1) * root.gap) / root.bars
                width: bw
                height: Math.max(2, root.level(index) / 100 * root.height)
                anchors.verticalCenter: parent.verticalCenter
                radius: bw / 2
                Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.accent2 }
                    GradientStop { position: 1.0; color: Theme.accent }
                }
                opacity: root.playing ? 0.95 : 0.35
                Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
            }
        }
    }
}

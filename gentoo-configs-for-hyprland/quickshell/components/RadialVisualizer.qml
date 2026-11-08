import QtQuick
import qs.config
import qs.services

// Circular audio spectrum drawn around a centre point (the album art). Uses real cava data,
// mirrored left/right so it is symmetric, with the bass at the bottom. Falls back to a gentle
// procedural animation if cava isn't running.
Canvas {
    id: c

    property int bars: 60
    property real innerRadius: 100
    property real maxLength: 36
    property bool playing: false
    property bool running: true
    property color colorA: Theme.accent2
    property color colorB: Theme.accent

    property var levels: []
    property var fake: []
    property int tickCount: 0
    property bool settled: true

    Timer {
        interval: 33
        repeat: true
        running: c.running && (c.playing || !c.settled)
        onTriggered: c.step()
    }

    function target(i) {
        if (!playing) return 0.03;
        const src = CavaService.active ? CavaService.values : fake;
        const n = src.length;
        if (n === 0) return 0.03;
        // mirrored spectrum: low -> high -> low around the circle, starting at the bottom
        const m = n * 2;
        const pos = (i / bars) * m;
        const i0 = Math.floor(pos) % m;
        const i1 = (i0 + 1) % m;
        const f = pos - Math.floor(pos);
        const v0 = src[i0 < n ? i0 : m - 1 - i0];
        const v1 = src[i1 < n ? i1 : m - 1 - i1];
        return Math.max(0.03, Math.min(1, ((v0 || 0) * (1 - f) + (v1 || 0) * f) / 100));
    }

    function step() {
        tickCount++;
        if (playing && !CavaService.active && tickCount % 3 === 0) {
            const a = [];
            for (let i = 0; i < 20; i++) a.push(18 + Math.random() * 70);
            fake = a;
        }
        if (levels.length !== bars) levels = new Array(bars).fill(0.03);
        let maxLevel = 0;
        for (let i = 0; i < bars; i++) {
            const t = target(i);
            const cur = levels[i];
            levels[i] = cur + (t - cur) * (t > cur ? 0.55 : 0.2);
            if (levels[i] > maxLevel) maxLevel = levels[i];
        }
        settled = !playing && maxLevel < 0.06;
        requestPaint();
    }

    onBarsChanged: { levels = []; requestPaint(); }
    onInnerRadiusChanged: requestPaint()
    onColorAChanged: requestPaint()
    onColorBChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const cx = width / 2, cy = height / 2;
        const n = bars;
        if (levels.length !== n) levels = new Array(n).fill(0.03);
        ctx.lineCap = "round";
        ctx.lineWidth = Math.max(2, (2 * Math.PI * innerRadius / n) * 0.55);
        for (let i = 0; i < n; i++) {
            const lv = levels[i];
            const a = Math.PI / 2 + (i / n) * Math.PI * 2;
            const r0 = innerRadius;
            const r1 = innerRadius + 3 + lv * maxLength;
            const cos = Math.cos(a), sin = Math.sin(a);
            ctx.strokeStyle = Qt.rgba(
                colorA.r + (colorB.r - colorA.r) * lv,
                colorA.g + (colorB.g - colorA.g) * lv,
                colorA.b + (colorB.b - colorA.b) * lv,
                0.45 + 0.55 * lv);
            ctx.beginPath();
            ctx.moveTo(cx + cos * r0, cy + sin * r0);
            ctx.lineTo(cx + cos * r1, cy + sin * r1);
            ctx.stroke();
        }
    }
}

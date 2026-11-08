import QtQuick

// Reads a wallpaper through a tiny hidden canvas and derives a colour scheme from it
// (no external tools). Call extract("/path/to/image.png"); listen to `extracted`.
Canvas {
    id: c

    property string source: ""
    property string status: ""
    property bool pending: false
    signal extracted(var colors)

    width: 64
    height: 36
    opacity: 0.01

    function extract(path) {
        if (source !== "") unloadImage(source);
        source = "file://" + path;
        pending = true;
        status = "Reading wallpaper…";
        loadImage(source);
        timeout.restart();
    }

    onImageLoaded: { timeout.stop(); requestPaint(); }
    Timer {
        id: timeout
        interval: 5000
        onTriggered: { c.pending = false; c.status = "Couldn't read that image"; }
    }

    function wrap(h) { return ((h % 1) + 1) % 1; }
    function hdist(a, b) { const d = Math.abs(a - b) % 1; return Math.min(d, 1 - d); }
    function clamp(x, lo, hi) { return Math.max(lo, Math.min(hi, x)); }

    function analyze(d) {
        const buckets = {};
        for (let i = 0; i < d.length; i += 4) {
            if (d[i + 3] < 200) continue;
            const key = ((d[i] >> 4) << 8) | ((d[i + 1] >> 4) << 4) | (d[i + 2] >> 4);
            let o = buckets[key];
            if (!o) { o = { n: 0, r: 0, g: 0, b: 0 }; buckets[key] = o; }
            o.n++; o.r += d[i]; o.g += d[i + 1]; o.b += d[i + 2];
        }
        const list = [];
        for (const k in buckets) {
            const o = buckets[k];
            const col = Qt.rgba(o.r / o.n / 255, o.g / o.n / 255, o.b / o.n / 255, 1);
            list.push({ n: o.n, h: col.hslHue < 0 ? 0 : col.hslHue, s: col.hslSaturation, l: col.hslLightness });
        }
        if (list.length === 0) return null;

        // background: the dominant dark colour, pushed very dark
        let dark = null;
        for (const b of list) if (b.l < 0.3 && (!dark || b.n > dark.n)) dark = b;
        if (!dark) { dark = list[0]; for (const b of list) if (b.l < dark.l) dark = b; }

        // accents: bright-ish, saturated colours, preferring big areas; each accent hue must differ
        function pick(avoid) {
            let best = null, bestScore = 0;
            for (const b of list) {
                if (b.l < 0.4 || b.l > 0.92 || b.s < 0.18) continue;
                let ok = true;
                for (const h of avoid) if (c.hdist(b.h, h) < 0.06) ok = false;
                if (!ok) continue;
                const score = Math.sqrt(b.n) * (b.s + 0.15) * (1 - Math.abs(b.l - 0.7));
                if (score > bestScore) { bestScore = score; best = b; }
            }
            return best;
        }
        let a1 = pick([]);
        if (!a1) { a1 = list[0]; for (const b of list) if (b.l > a1.l) a1 = b; }
        const a2 = pick([a1.h]);
        const a3 = pick(a2 ? [a1.h, a2.h] : [a1.h]);
        const h1 = a1.h;
        const h2 = a2 ? a2.h : wrap(h1 - 0.07);
        const h3 = a3 ? a3.h : wrap(h1 + 0.07);
        const sat = s => clamp(s * 1.1 + 0.1, 0.45, 0.95);

        return {
            base: Qt.hsla(dark.h, clamp(dark.s, 0.15, 0.55), 0.07, 1).toString(),
            accent: Qt.hsla(h1, sat(Math.max(0.3, a1.s)), 0.72, 1).toString(),
            accent2: Qt.hsla(h2, sat(a2 ? a2.s : a1.s), 0.72, 1).toString(),
            violet: Qt.hsla(h3, sat(a3 ? a3.s : a1.s), 0.74, 1).toString(),
            text: Qt.hsla(h1, 0.6, 0.93, 1).toString(),
            textDim: Qt.hsla(h1, 0.3, 0.74, 1).toString(),
            textMute: Qt.hsla(h1, 0.2, 0.52, 1).toString()
        };
    }

    onPaint: {
        if (!pending || source === "" || !isImageLoaded(source)) return;
        pending = false;
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.drawImage(source, 0, 0, width, height);
        const pal = analyze(ctx.getImageData(0, 0, width, height).data);
        if (pal) { status = "Palette applied from wallpaper"; extracted(pal); }
        else status = "Couldn't read colours from that image";
    }
}

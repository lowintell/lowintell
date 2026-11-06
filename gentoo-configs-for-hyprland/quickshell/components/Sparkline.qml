import QtQuick
import qs.config

// Rolling area graph. `values` is an array of numbers, newest last. maxValue <= 0 means auto-scale.
Canvas {
    id: c

    property var values: []
    property real maxValue: 100
    property int points: 60
    property color lineColor: Theme.accent
    property bool filled: true

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLineColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        // baseline grid
        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05);
        ctx.lineWidth = 1;
        for (let g = 1; g < 4; g++) {
            const gy = Math.round(height * g / 4) + 0.5;
            ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke();
        }

        const n = values.length;
        if (n < 2) return;
        let mx = maxValue;
        if (mx <= 0) {
            mx = 1;
            for (let i = 0; i < n; i++) mx = Math.max(mx, values[i]);
            mx *= 1.15;
        }
        const step = width / (points - 1);
        const pad = 2;
        const h = height - pad * 2;
        function px(i) { return width - (n - 1 - i) * step; }
        function py(v) { return pad + h - Math.max(0, Math.min(1, v / mx)) * h; }

        ctx.beginPath();
        ctx.moveTo(px(0), py(values[0]));
        for (let i = 1; i < n; i++) ctx.lineTo(px(i), py(values[i]));

        if (filled) {
            ctx.save();
            ctx.lineTo(px(n - 1), height);
            ctx.lineTo(px(0), height);
            ctx.closePath();
            const grad = ctx.createLinearGradient(0, 0, 0, height);
            grad.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.32));
            grad.addColorStop(1, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.0));
            ctx.fillStyle = grad;
            ctx.fill();
            ctx.restore();

            ctx.beginPath();
            ctx.moveTo(px(0), py(values[0]));
            for (let i = 1; i < n; i++) ctx.lineTo(px(i), py(values[i]));
        }
        ctx.lineWidth = 1.6;
        ctx.lineJoin = "round";
        ctx.strokeStyle = lineColor;
        ctx.stroke();
    }
}

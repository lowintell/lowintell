import QtQuick
import qs.config

// Vector weather glyphs drawn on a Canvas (no icon font or image assets needed).
// kind: clear | partly | cloud | fog | rain | snow | storm
Canvas {
    id: c

    property string kind: "clear"
    property bool isDay: true

    implicitWidth: 24
    implicitHeight: 24

    onKindChanged: requestPaint()
    onIsDayChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const s = Math.min(width, height);
        const sunC = "#ffd9a3", cloudC = "#c6cdf7", cloudDark = "#8a92c8", dropC = "#86c8ff", moonC = "#dde1ff";
        ctx.lineCap = "round";

        function sun(cx, cy, r, rays) {
            ctx.fillStyle = sunC;
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill();
            if (!rays) return;
            ctx.strokeStyle = sunC;
            ctx.lineWidth = Math.max(1, s * 0.05);
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4;
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * r * 1.45, cy + Math.sin(a) * r * 1.45);
                ctx.lineTo(cx + Math.cos(a) * r * 1.85, cy + Math.sin(a) * r * 1.85);
                ctx.stroke();
            }
        }

        function moon(cx, cy, r) {
            ctx.fillStyle = moonC;
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill();
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath(); ctx.arc(cx + r * 0.55, cy - r * 0.35, r * 0.85, 0, Math.PI * 2); ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        }

        function cloud(x, y, w, color) {
            const h = w * 0.62;
            ctx.fillStyle = color;
            ctx.beginPath();
            ctx.arc(x + w * 0.30, y + h * 0.62, h * 0.38, Math.PI * 0.5, Math.PI * 1.5);
            ctx.arc(x + w * 0.50, y + h * 0.38, h * 0.40, Math.PI, 0);
            ctx.arc(x + w * 0.74, y + h * 0.60, h * 0.34, Math.PI * 1.5, Math.PI * 0.5);
            ctx.closePath();
            ctx.fill();
        }

        function drops(n, y0) {
            ctx.strokeStyle = dropC;
            ctx.lineWidth = Math.max(1, s * 0.06);
            for (let i = 0; i < n; i++) {
                const x = s * (0.28 + i * 0.2);
                ctx.beginPath(); ctx.moveTo(x, s * y0); ctx.lineTo(x - s * 0.06, s * (y0 + 0.17)); ctx.stroke();
            }
        }

        switch (kind) {
        case "clear":
            if (isDay) sun(s / 2, s / 2, s * 0.21, true); else moon(s * 0.5, s * 0.5, s * 0.3);
            break;
        case "partly":
            if (isDay) sun(s * 0.63, s * 0.34, s * 0.16, true); else moon(s * 0.62, s * 0.33, s * 0.2);
            cloud(s * 0.06, s * 0.36, s * 0.8, cloudC);
            break;
        case "cloud":
            cloud(s * 0.32, s * 0.12, s * 0.6, cloudDark);
            cloud(s * 0.06, s * 0.28, s * 0.84, cloudC);
            break;
        case "fog":
            cloud(s * 0.14, s * 0.08, s * 0.72, cloudC);
            ctx.strokeStyle = cloudDark;
            ctx.lineWidth = Math.max(1, s * 0.06);
            for (let i = 0; i < 3; i++) {
                const y = s * (0.62 + i * 0.12);
                ctx.beginPath(); ctx.moveTo(s * (0.16 + i * 0.04), y); ctx.lineTo(s * (0.84 - i * 0.06), y); ctx.stroke();
            }
            break;
        case "rain":
            cloud(s * 0.08, s * 0.08, s * 0.84, cloudC);
            drops(3, 0.62);
            break;
        case "snow":
            cloud(s * 0.08, s * 0.08, s * 0.84, cloudC);
            ctx.fillStyle = "#eef0ff";
            for (let i = 0; i < 3; i++) {
                ctx.beginPath(); ctx.arc(s * (0.3 + i * 0.2), s * (0.72 + (i % 2) * 0.1), s * 0.04, 0, Math.PI * 2); ctx.fill();
            }
            break;
        case "storm":
            cloud(s * 0.08, s * 0.06, s * 0.84, cloudDark);
            ctx.fillStyle = sunC;
            ctx.beginPath();
            ctx.moveTo(s * 0.52, s * 0.52);
            ctx.lineTo(s * 0.36, s * 0.76);
            ctx.lineTo(s * 0.49, s * 0.76);
            ctx.lineTo(s * 0.43, s * 0.95);
            ctx.lineTo(s * 0.66, s * 0.67);
            ctx.lineTo(s * 0.52, s * 0.67);
            ctx.closePath();
            ctx.fill();
            break;
        }
    }
}

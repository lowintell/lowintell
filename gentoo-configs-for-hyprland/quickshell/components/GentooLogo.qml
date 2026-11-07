import QtQuick
import qs.config

// Small stylised Gentoo "orb" (tilted pebble with a cut-out and a tail), drawn as a vector.
Canvas {
    implicitWidth: 22
    implicitHeight: 22

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const s = Math.min(width, height);
        const r = s * 0.36;

        ctx.save();
        ctx.translate(s * 0.46, s * 0.54);
        ctx.rotate(-0.6);

        const g = ctx.createLinearGradient(-r, -r, r, r);
        g.addColorStop(0, Theme.accent);
        g.addColorStop(1, Theme.violet);
        ctx.fillStyle = g;

        // body
        ctx.save();
        ctx.scale(1, 0.74);
        ctx.beginPath();
        ctx.arc(0, 0, r, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();

        // tail
        ctx.beginPath();
        ctx.moveTo(r * 0.5, -r * 0.4);
        ctx.lineTo(r * 1.4, -r * 0.62);
        ctx.lineTo(r * 0.85, r * 0.12);
        ctx.closePath();
        ctx.fill();

        // cut-out
        ctx.globalCompositeOperation = "destination-out";
        ctx.save();
        ctx.translate(-r * 0.12, r * 0.02);
        ctx.scale(1, 0.55);
        ctx.beginPath();
        ctx.arc(0, 0, r * 0.42, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        ctx.globalCompositeOperation = "source-over";

        ctx.restore();
    }
}

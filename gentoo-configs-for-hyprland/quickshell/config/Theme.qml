pragma Singleton
import QtQuick
import Quickshell

// Visual system. Everything here follows Settings live, so colours/sizes/fonts can be changed from the
// settings panel without touching code. Defaults are sampled from the dusk-seascape wallpaper.
Singleton {
    // base surfaces (derived from one background tint)
    readonly property color base: Settings.color("base")
    readonly property color bg0: Qt.darker(base, 1.7)
    readonly property color bg1: base
    readonly property color bg2: Qt.lighter(base, 1.25)
    readonly property color surface: Qt.lighter(base, 1.7)
    readonly property color surfaceHi: Qt.lighter(base, 2.2)
    readonly property color line: Qt.lighter(base, 3.0)

    // text
    readonly property color text: Settings.color("text")
    readonly property color textDim: Settings.color("textDim")
    readonly property color textMute: Settings.color("textMute")

    // accents
    readonly property color accent: Settings.color("accent")
    readonly property color accent2: Settings.color("accent2")
    readonly property color violet: Settings.color("violet")
    readonly property color good: Settings.color("good")
    readonly property color warn: Settings.color("warn")
    readonly property color bad: Settings.color("bad")

    // glass
    readonly property color glass: Qt.rgba(base.r, base.g, base.b, Settings.panelOpacity)
    readonly property color glassBar: Qt.rgba(base.r, base.g, base.b, Settings.barOpacity)
    readonly property color hairline: Qt.rgba(text.r, text.g, text.b, 0.10)
    readonly property color tile: Qt.rgba(text.r, text.g, text.b, 0.06)
    readonly property color tileHover: Qt.rgba(text.r, text.g, text.b, 0.12)

    // metrics
    readonly property int radius: Settings.radius
    readonly property int radiusSm: Math.max(4, Math.round(Settings.radius * 0.625))
    readonly property int barHeight: Settings.barHeight
    readonly property int barMargin: Settings.barMargin
    readonly property int pad: 16
    readonly property int shadowPad: 8

    // motion
    readonly property int animFast: Math.round(120 * Settings.animSpeed)
    readonly property int animMed: Math.round(220 * Settings.animSpeed)
    readonly property int animSlow: Math.round(380 * Settings.animSpeed)

    // type
    readonly property string fontSans: Settings.fontSans
    readonly property string fontMono: Settings.fontMono
    readonly property string fontIcon: "Material Symbols Rounded"

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}

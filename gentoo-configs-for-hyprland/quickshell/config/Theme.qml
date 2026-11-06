pragma Singleton
import QtQuick
import Quickshell

// Visual system. Palette is sampled from the dusk-seascape wallpaper:
// ink-navy shoreline, slate-indigo cloud banks, lavender-white highlights.
Singleton {
    // base surfaces
    readonly property color bg0: "#090a12"
    readonly property color bg1: "#10111d"
    readonly property color bg2: "#171930"
    readonly property color surface: "#1e2140"
    readonly property color surfaceHi: "#2a2e56"
    readonly property color line: "#3a4070"

    // text
    readonly property color text: "#e0e4ff"
    readonly property color textDim: "#a3a9d6"
    readonly property color textMute: "#6c7299"

    // accents
    readonly property color accent: "#a5b0ff"    // periwinkle (cloud highlight)
    readonly property color accent2: "#86c8ff"   // cool cyan (sea glint)
    readonly property color violet: "#b89cff"
    readonly property color good: "#8fe3c0"
    readonly property color warn: "#ffd6a0"
    readonly property color bad: "#ff8fa6"

    // glass
    readonly property color glass: Qt.rgba(0.05, 0.055, 0.11, 0.62)
    readonly property color glassBar: Qt.rgba(0.05, 0.055, 0.11, 0.42)
    readonly property color hairline: Qt.rgba(0.75, 0.8, 1.0, 0.10)
    readonly property color tile: Qt.rgba(0.7, 0.75, 1.0, 0.06)
    readonly property color tileHover: Qt.rgba(0.7, 0.75, 1.0, 0.12)

    // metrics
    readonly property int radius: 16
    readonly property int radiusSm: 10
    readonly property int barHeight: 38
    readonly property int barMargin: 10
    readonly property int pad: 16
    readonly property int shadowPad: 8

    // motion
    readonly property int animFast: 120
    readonly property int animMed: 220
    readonly property int animSlow: 380

    // type
    readonly property string fontSans: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property string fontIcon: "Material Symbols Rounded"

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}

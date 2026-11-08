pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// All user-changeable settings. Persisted to ~/.local/state/qs-glass/settings.json.
// Change values through Settings.set("key", value) so they get saved.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/qs-glass"
    property bool loaded: false

    // ── colours ──
    readonly property var defaultColors: ({
        base: "#0d0e1c", accent: "#a5b0ff", accent2: "#86c8ff", violet: "#b89cff",
        text: "#e0e4ff", textDim: "#a3a9d6", textMute: "#6c7299",
        good: "#8fe3c0", warn: "#ffd6a0", bad: "#ff8fa6"
    })
    property var colors: ({})            // overrides on top of defaultColors
    property var savedSchemes: []        // [{ name, colors }]

    // ── general ──
    property bool clock24: true
    property string dateFormat: "ddd d MMM"
    property int workspaceCount: 5
    property bool showWindowTitle: true
    property bool gpuPolling: true
    property int nightLightTemp: 4200
    property string weatherName: "Bourj Hammoud, Lebanon"
    property real weatherLat: 33.8889
    property real weatherLon: 35.5361
    property bool useFahrenheit: false
    property string weatherModel: ""

    // ── appearance ──
    property string barStyle: "islands"  // islands | full
    property int barHeight: 38
    property int barMargin: 10
    property real barOpacity: 0.42
    property real panelOpacity: 0.62
    property int radius: 16
    property real animSpeed: 1.0
    property string fontSans: "Inter"
    property string fontMono: "JetBrains Mono"

    // ── media ──
    property string mediaStyle: "circle" // circle | classic
    property bool visualizerEnabled: true
    property int radialBars: 60
    property bool spinArt: false
    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    property string wallpaperBackend: "awww"        // awww | swaybg | custom
    property string wallpaperTransition: "grow"     // awww transition type
    property string wallpaperCommand: "swaybg -i %f -m fill"   // custom backend; %f = image path
    property bool wallpaperApply: true              // clicking a wallpaper sets it
    property bool wallpaperRecolor: true            // ... and recolours the shell from it
    property string lastWallpaper: ""
    // apply colours to other programs
    property bool exportAuto: true
    property bool exportKitty: true
    property bool exportHyprland: true
    property bool exportFastfetch: true

    readonly property var keys: [
        "clock24", "dateFormat", "workspaceCount", "showWindowTitle", "gpuPolling", "nightLightTemp",
        "weatherName", "weatherLat", "weatherLon", "useFahrenheit", "weatherModel",
        "barStyle", "barHeight", "barMargin", "barOpacity", "panelOpacity", "radius", "animSpeed",
        "fontSans", "fontMono", "mediaStyle", "visualizerEnabled", "radialBars", "spinArt", "wallpaperDir",
        "wallpaperBackend", "wallpaperTransition", "wallpaperCommand", "wallpaperApply", "wallpaperRecolor", "lastWallpaper",
        "exportAuto", "exportKitty", "exportHyprland", "exportFastfetch"
    ]
    readonly property var appearanceKeys: [
        "barStyle", "barHeight", "barMargin", "barOpacity", "panelOpacity", "radius", "animSpeed", "fontSans", "fontMono"
    ]
    readonly property var appearanceDefaults: ({
        barStyle: "islands", barHeight: 38, barMargin: 10, barOpacity: 0.42, panelOpacity: 0.62,
        radius: 16, animSpeed: 1.0, fontSans: "Inter", fontMono: "JetBrains Mono"
    })

    function set(key, value) { root[key] = value; save(); }

    function resetAppearance() {
        for (const k of appearanceKeys) root[k] = appearanceDefaults[k];
        save();
    }

    // colours
    function color(role) {
        const v = colors[role];
        return v !== undefined ? v : defaultColors[role];
    }
    function allColors() {
        const o = {};
        for (const k of Object.keys(defaultColors)) o[k] = color(k);
        return o;
    }
    function setColor(role, hex) {
        const c = Object.assign({}, colors);
        c[role] = hex;
        colors = c;
        save();
    }
    function applyColors(obj) {
        const c = {};
        for (const k of Object.keys(obj)) c[k] = obj[k];
        colors = c;
        save();
    }
    function resetColors() { colors = ({}); save(); }
    function saveScheme(name) {
        name = (name || "").trim();
        if (name === "") return false;
        const list = savedSchemes.filter(s => s.name !== name);
        list.push({ name: name, colors: allColors() });
        savedSchemes = list;
        save();
        return true;
    }
    function deleteScheme(name) {
        savedSchemes = savedSchemes.filter(s => s.name !== name);
        save();
    }

    // persistence
    function snapshot() {
        const o = {};
        for (const k of keys) o[k] = root[k];
        o.colors = colors;
        o.savedSchemes = savedSchemes;
        return o;
    }
    function apply(o) {
        for (const k of keys) if (o[k] !== undefined) root[k] = o[k];
        if (wallpaperBackend === "swww") wallpaperBackend = "awww";
        if (o.colors) colors = o.colors;
        if (o.savedSchemes) savedSchemes = o.savedSchemes;
    }
    function save() { if (loaded) saveTimer.restart(); }

    Timer { id: saveTimer; interval: 600; onTriggered: file.setText(JSON.stringify(root.snapshot(), null, 2)) }
    Process { command: ["mkdir", "-p", root.stateDir]; running: true }
    FileView {
        id: file
        path: root.stateDir + "/settings.json"
        printErrors: false
        onLoaded: { try { root.apply(JSON.parse(text())); } catch (e) {} root.loaded = true; }
        onLoadFailed: root.loaded = true
    }
}

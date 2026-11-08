import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

ScrollTab {
    id: root

    property bool active: false
    property string role: "accent"
    property var undoColors: null
    property var files: []

    readonly property var roles: [
        { key: "base", label: "Background" },
        { key: "accent", label: "Accent" },
        { key: "accent2", label: "Accent 2" },
        { key: "violet", label: "Accent 3" },
        { key: "text", label: "Text" },
        { key: "textDim", label: "Text dim" },
        { key: "textMute", label: "Text muted" },
        { key: "good", label: "Good" },
        { key: "warn", label: "Warning" },
        { key: "bad", label: "Error" }
    ]

    readonly property var presets: [
        { name: "Dusk", colors: { base: "#0d0e1c", accent: "#a5b0ff", accent2: "#86c8ff", violet: "#b89cff", text: "#e0e4ff", textDim: "#a3a9d6", textMute: "#6c7299" } },
        { name: "Midnight cyan", colors: { base: "#060b14", accent: "#4cc9f0", accent2: "#4895ef", violet: "#7b6cf6", text: "#dff6ff", textDim: "#94b8cc", textMute: "#5a7a8c" } },
        { name: "Ember", colors: { base: "#140a0a", accent: "#ff9e6b", accent2: "#ffd27a", violet: "#ff7aa8", text: "#ffeee6", textDim: "#cfa393", textMute: "#8a6a60" } },
        { name: "Forest", colors: { base: "#0a130e", accent: "#8fe3a5", accent2: "#7fd6d1", violet: "#b7d98a", text: "#e6fff0", textDim: "#9cc4aa", textMute: "#607a68" } },
        { name: "Rose", colors: { base: "#160b13", accent: "#f5a3c7", accent2: "#c9a3f5", violet: "#ff9eb5", text: "#ffeaf3", textDim: "#cfa0b6", textMute: "#8a6678" } },
        { name: "Mono", colors: { base: "#0e0e10", accent: "#d0d0d8", accent2: "#a8a8b4", violet: "#8a8a98", text: "#f0f0f4", textDim: "#a0a0aa", textMute: "#66666e" } }
    ]

    // set the wallpaper and/or recolour the shell from it, per the options below
    function pick(path) {
        if (Settings.wallpaperApply) WallpaperService.set(path);
        if (Settings.wallpaperRecolor) extractor.extract(path);
    }

    function applyScheme(colors) {
        undoColors = Settings.allColors();
        Settings.applyColors(colors);
    }

    function refreshFiles() {
        lister.running = false;
        lister.command = ["sh", "-c", "ls -1t \"$1\" 2>/dev/null | head -n 80", "sh", Settings.wallpaperDir];
        lister.running = true;
    }
    onActiveChanged: if (active) refreshFiles()

    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.split("\n")) if (/\.(png|jpe?g|webp|bmp)$/i.test(l)) out.push(l);
                root.files = out.slice(0, 12);
            }
        }
    }

    // hidden helper (no layout footprint)
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
        PaletteExtractor { id: extractor; onExtracted: pal => root.applyScheme(pal) }
    }

    // ── presets, saved schemes ──
    SettingsCard {
        title: "Colour schemes"

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: root.presets
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    height: 32
                    width: chipRow.implicitWidth + 22
                    radius: 10
                    color: chipMa.containsMouse ? Theme.tileHover : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: Theme.hairline
                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6
                        Repeater {
                            model: ["base", "accent", "accent2", "violet"]
                            Rectangle { required property string modelData; width: 12; height: 12; radius: 6; color: chip.modelData.colors[modelData]; border.width: 1; border.color: Theme.hairline }
                        }
                        Text { text: chip.modelData.name; color: Theme.textDim; font.family: Theme.fontSans; font.pixelSize: 12 }
                    }
                    MouseArea { id: chipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyScheme(chip.modelData.colors) }
                }
            }
        }

        // saved
        Text {
            visible: Settings.savedSchemes.length > 0
            text: "Saved by you"
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 11
        }
        Repeater {
            model: Settings.savedSchemes
            delegate: Rectangle {
                id: saved
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 10
                color: savedMa.containsMouse ? Theme.tileHover : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: Theme.hairline
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6
                    spacing: 8
                    Repeater {
                        model: ["base", "accent", "accent2", "violet"]
                        Rectangle { required property string modelData; width: 14; height: 14; radius: 7; color: saved.modelData.colors[modelData]; border.width: 1; border.color: Theme.hairline }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: saved.modelData.name
                        color: Theme.text
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    IconButton { size: 28; iconSize: 16; icon: "delete"; iconColor: Theme.textMute; onClicked: Settings.deleteScheme(saved.modelData.name) }
                }
                MouseArea {
                    id: savedMa
                    anchors.fill: parent
                    anchors.rightMargin: 40
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyScheme(saved.modelData.colors)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            FieldInput { id: nameField; Layout.fillWidth: true; placeholder: "Name this colour scheme to save it" }
            PillButton {
                text: "Save current"
                icon: "save"
                onClicked: { if (Settings.saveScheme(nameField.currentText)) nameField.currentText = ""; }
            }
        }
        RowLayout {
            spacing: 8
            PillButton { text: "Undo last change"; icon: "undo"; visible: root.undoColors !== null; onClicked: { Settings.applyColors(root.undoColors); root.undoColors = null; } }
            PillButton { text: "Reset to default"; icon: "restart_alt"; danger: true; onClicked: { root.undoColors = Settings.allColors(); Settings.resetColors(); } }
        }
    }

    // ── from wallpaper ──
    SettingsCard {
        title: "From wallpaper"

        Text {
            Layout.fillWidth: true
            text: "Click a wallpaper to set it and recolour the shell from it (both can be switched off below). Use “Save current” above to keep the colours."
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            FieldInput {
                Layout.fillWidth: true
                mono: true
                placeholder: "Wallpaper folder"
                value: Settings.wallpaperDir
                onCommitted: t => { Settings.set("wallpaperDir", t.trim()); root.refreshFiles(); }
            }
            IconButton { size: 32; iconSize: 17; icon: "refresh"; onClicked: root.refreshFiles() }
        }

        SettingRow {
            label: "Wallpaper backend"
            Segmented {
                current: Settings.wallpaperBackend
                options: [ { value: "awww", label: "awww" }, { value: "swaybg", label: "swaybg" }, { value: "custom", label: "Custom" } ]
                onPicked: v => Settings.set("wallpaperBackend", v)
            }
        }
        SettingRow {
            visible: Settings.wallpaperBackend === "awww"
            label: "Transition"
            Segmented {
                current: Settings.wallpaperTransition
                options: [ { value: "fade", label: "Fade" }, { value: "grow", label: "Grow" }, { value: "wave", label: "Wave" }, { value: "wipe", label: "Wipe" }, { value: "random", label: "Random" }, { value: "none", label: "None" } ]
                onPicked: v => Settings.set("wallpaperTransition", v)
            }
        }
        SettingRow {
            visible: Settings.wallpaperBackend === "custom"
            label: "Command"
            desc: "%f is replaced by the image path"
            FieldInput { implicitWidth: 260; mono: true; value: Settings.wallpaperCommand; onCommitted: t => Settings.set("wallpaperCommand", t.trim()) }
        }
        SettingRow {
            label: "Set wallpaper on click"
            ToggleSwitch { checked: Settings.wallpaperApply; onToggled: v => Settings.set("wallpaperApply", v) }
        }
        SettingRow {
            label: "Recolour shell on click"
            ToggleSwitch { checked: Settings.wallpaperRecolor; onToggled: v => Settings.set("wallpaperRecolor", v) }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 8
            rowSpacing: 8
            Repeater {
                model: root.active ? root.files : []
                delegate: ClippingRectangle {
                    id: thumb
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 84
                    radius: 10
                    color: Theme.surface
                    Image {
                        anchors.fill: parent
                        source: "file://" + Settings.wallpaperDir + "/" + thumb.modelData
                        sourceSize: Qt.size(260, 150)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.width: 2
                        border.color: thumbMa.containsMouse ? Theme.accent : "transparent"
                    }
                    MouseArea {
                        id: thumbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(Settings.wallpaperDir + "/" + thumb.modelData)
                    }
                }
            }
        }
        Text {
            visible: root.files.length === 0
            text: "No images found in that folder."
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 11
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            FieldInput { id: pathField; Layout.fillWidth: true; mono: true; placeholder: "…or paste a full path to an image" }
            PillButton { text: "Use"; icon: "wallpaper"; onClicked: { if (pathField.currentText.trim() !== "") root.pick(pathField.currentText.trim()); } }
        }
        Text {
            visible: extractor.status !== ""
            text: extractor.status
            color: Theme.accent
            font.family: Theme.fontSans
            font.pixelSize: 11
        }
    }

    // ── manual colours ──
    SettingsCard {
        title: "Edit colours"

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: root.roles
                delegate: Rectangle {
                    id: roleChip
                    required property var modelData
                    readonly property bool on: root.role === modelData.key
                    height: 32
                    width: roleRow.implicitWidth + 22
                    radius: 10
                    color: on ? Theme.alpha(Theme.accent, 0.2) : (roleMa.containsMouse ? Theme.tileHover : Qt.rgba(1, 1, 1, 0.06))
                    border.width: 1
                    border.color: on ? Theme.alpha(Theme.accent, 0.7) : Theme.hairline
                    RowLayout {
                        id: roleRow
                        anchors.centerIn: parent
                        spacing: 7
                        Rectangle { width: 14; height: 14; radius: 7; color: Settings.color(roleChip.modelData.key); border.width: 1; border.color: Theme.hairline }
                        Text { text: roleChip.modelData.label; color: roleChip.on ? Theme.text : Theme.textDim; font.family: Theme.fontSans; font.pixelSize: 12 }
                    }
                    MouseArea { id: roleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.role = roleChip.modelData.key }
                }
            }
        }

        ColorPicker {
            Layout.fillWidth: true
            value: Settings.color(root.role)
            onPicked: hex => Settings.setColor(root.role, hex)
        }
    }
}

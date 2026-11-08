import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

ScrollTab {
    SettingsCard {
        title: "Match other apps"

        SettingRow {
            label: "Update automatically"
            desc: "Whenever the colours change (picker, preset, saved scheme or wallpaper)"
            ToggleSwitch { checked: Settings.exportAuto; onToggled: v => Settings.set("exportAuto", v) }
        }
        SettingRow {
            label: "Terminal (kitty)"
            desc: "Writes ~/.config/kitty/qs-colors.conf and reloads every open kitty window"
            ToggleSwitch { checked: Settings.exportKitty; onToggled: v => Settings.set("exportKitty", v) }
        }
        SettingRow {
            label: "Hyprland borders"
            desc: "Writes ~/.config/hypr/qs-colors.lua and applies it live"
            ToggleSwitch { checked: Settings.exportHyprland; onToggled: v => Settings.set("exportHyprland", v) }
        }
        SettingRow {
            label: "Fastfetch"
            desc: "Renders ~/.config/fastfetch/config.template.jsonc into config.jsonc (used next time fastfetch runs)"
            ToggleSwitch { checked: Settings.exportFastfetch; onToggled: v => Settings.set("exportFastfetch", v) }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            PillButton { text: "Apply now"; icon: "sync"; onClicked: ExportService.apply() }
            Text {
                Layout.fillWidth: true
                text: ExportService.status
                color: Theme.accent
                font.family: Theme.fontSans
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    SettingsCard {
        title: "One-time setup"

        Text {
            Layout.fillWidth: true
            text: "Add these once. Until then the files are written but nothing reads them. Back up each file first."
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
        CodeBlock {
            title: "kitty.conf: add as the LAST line (later lines win over your old colours)"
            code: "include qs-colors.conf"
        }
        Text {
            Layout.fillWidth: true
            text: "Fastfetch: copy config.template.jsonc into ~/.config/fastfetch/ (back up config.jsonc first). From then on edit the template, not config.jsonc; the shell rewrites config.jsonc from it."
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
        CodeBlock {
            title: "~/.config/hypr/glass.lua: add anywhere (safe if the file is missing)"
            code: "local ok, c = pcall(require, \"qs-colors\")\nif ok and type(c) == \"table\" then\n\thl.config({\n\t\tgeneral = {\n\t\t\tcol = {\n\t\t\t\tactive_border = { colors = { c.active1, c.active2 }, angle = 45 },\n\t\t\t\tinactive_border = c.inactive,\n\t\t\t},\n\t\t},\n\t})\nend"
        }
    }
}

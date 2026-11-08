import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

ScrollTab {
    SettingsCard {
        title: "Clock & bar"

        SettingRow {
            label: "24-hour clock"
            ToggleSwitch { checked: Settings.clock24; onToggled: v => Settings.set("clock24", v) }
        }
        SettingRow {
            label: "Date format"
            Segmented {
                current: Settings.dateFormat
                options: [
                    { value: "ddd d MMM", label: "Fri 6 Nov" },
                    { value: "d MMM", label: "6 Nov" },
                    { value: "dddd d MMMM", label: "Friday 6 November" }
                ]
                onPicked: v => Settings.set("dateFormat", v)
            }
        }
        SettingRow {
            label: "Show window title"
            desc: "Active window's title on the left of the bar"
            ToggleSwitch { checked: Settings.showWindowTitle; onToggled: v => Settings.set("showWindowTitle", v) }
        }
        SettingRow {
            label: "Workspaces shown"
            desc: "Minimum number of dots; the bar grows if you use a higher one"
            IconButton { size: 28; iconSize: 16; icon: "remove"; onClicked: Settings.set("workspaceCount", Math.max(1, Settings.workspaceCount - 1)) }
            Text {
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                text: Settings.workspaceCount
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 13
            }
            IconButton { size: 28; iconSize: 16; icon: "add"; onClicked: Settings.set("workspaceCount", Math.min(10, Settings.workspaceCount + 1)) }
        }
    }

    SettingsCard {
        title: "Weather"

        SettingRow {
            label: "Location name"
            FieldInput { implicitWidth: 230; value: Settings.weatherName; onCommitted: t => { if (t.trim() !== "") Settings.set("weatherName", t.trim()); } }
        }
        SettingRow {
            label: "Latitude"
            FieldInput {
                implicitWidth: 140; mono: true
                value: String(Settings.weatherLat)
                onCommitted: t => { const n = parseFloat(t); if (!isNaN(n) && n >= -90 && n <= 90) Settings.set("weatherLat", n); }
            }
        }
        SettingRow {
            label: "Longitude"
            FieldInput {
                implicitWidth: 140; mono: true
                value: String(Settings.weatherLon)
                onCommitted: t => { const n = parseFloat(t); if (!isNaN(n) && n >= -180 && n <= 180) Settings.set("weatherLon", n); }
            }
        }
        SettingRow {
            label: "Quick locations"
            PillButton { text: "Bourj Hammoud"; onClicked: { Settings.set("weatherName", "Bourj Hammoud, Lebanon"); Settings.set("weatherLat", 33.8889); Settings.set("weatherLon", 35.5361); } }
            PillButton { text: "Beirut"; onClicked: { Settings.set("weatherName", "Beirut, Lebanon"); Settings.set("weatherLat", 33.8938); Settings.set("weatherLon", 35.5018); } }
        }
        SettingRow {
            label: "Units"
            Segmented {
                current: Settings.useFahrenheit
                options: [ { value: false, label: "°C" }, { value: true, label: "°F" } ]
                onPicked: v => Settings.set("useFahrenheit", v)
            }
        }
        SettingRow {
            label: "Weather model"
            desc: "Optional Open-Meteo model, e.g. ecmwf_ifs025 or icon_global. Empty = automatic"
            FieldInput { implicitWidth: 170; mono: true; placeholder: "automatic"; value: Settings.weatherModel; onCommitted: t => Settings.set("weatherModel", t.trim()) }
        }
    }

    SettingsCard {
        title: "System"

        SettingRow {
            label: "Poll GPU stats"
            desc: "Only while the System panel is open"
            ToggleSwitch { checked: Settings.gpuPolling; onToggled: v => Settings.set("gpuPolling", v) }
        }
        SliderRow {
            label: "Night light"
            from: 2500; to: 6500; step: 100
            value: Settings.nightLightTemp
            suffix: " K"
            onMoved: v => Settings.set("nightLightTemp", v)
        }
    }
}

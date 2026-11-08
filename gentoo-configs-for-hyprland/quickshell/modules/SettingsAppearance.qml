import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

ScrollTab {
    SettingsCard {
        title: "Bar"

        SettingRow {
            label: "Style"
            desc: "Floating islands, or one full-width strip"
            Segmented {
                current: Settings.barStyle
                options: [ { value: "islands", label: "Islands" }, { value: "full", label: "Full width" } ]
                onPicked: v => Settings.set("barStyle", v)
            }
        }
        SliderRow { label: "Height"; from: 28; to: 56; step: 1; value: Settings.barHeight; suffix: " px"; onMoved: v => Settings.set("barHeight", v) }
        SliderRow { label: "Edge margin"; from: 8; to: 28; step: 1; value: Settings.barMargin; suffix: " px"; onMoved: v => Settings.set("barMargin", v) }
        SliderRow { label: "Bar opacity"; from: 0; to: 1; step: 0.01; value: Settings.barOpacity; displayScale: 100; suffix: " %"; onMoved: v => Settings.set("barOpacity", v) }
    }

    SettingsCard {
        title: "Panels"

        SliderRow { label: "Panel opacity"; from: 0.2; to: 0.95; step: 0.01; value: Settings.panelOpacity; displayScale: 100; suffix: " %"; onMoved: v => Settings.set("panelOpacity", v) }
        SliderRow { label: "Corner radius"; from: 6; to: 28; step: 1; value: Settings.radius; suffix: " px"; onMoved: v => Settings.set("radius", v) }
        SliderRow { label: "Animation speed"; from: 0.25; to: 2; step: 0.05; value: Settings.animSpeed; decimals: 2; suffix: " ×"; onMoved: v => Settings.set("animSpeed", v) }
    }

    SettingsCard {
        title: "Fonts"

        SettingRow {
            label: "Interface font"
            desc: "Any installed family name"
            FieldInput { implicitWidth: 200; value: Settings.fontSans; onCommitted: t => { if (t.trim() !== "") Settings.set("fontSans", t.trim()); } }
        }
        SettingRow {
            label: "Monospace font"
            desc: "Clock, numbers and graphs"
            FieldInput { implicitWidth: 200; value: Settings.fontMono; onCommitted: t => { if (t.trim() !== "") Settings.set("fontMono", t.trim()); } }
        }
    }

    PillButton {
        text: "Reset appearance to defaults"
        icon: "restart_alt"
        danger: true
        onClicked: Settings.resetAppearance()
    }
}

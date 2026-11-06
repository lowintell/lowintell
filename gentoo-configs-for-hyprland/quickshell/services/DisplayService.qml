pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Backlight via brightnessctl, night light via hyprsunset.
Singleton {
    id: root

    property real brightness: 1
    property bool brightnessAvailable: false
    property bool nightLight: false
    property real _pending: -1

    function refresh() { if (!getter.running) getter.running = true; }

    function setBrightness(v) {
        brightness = Math.max(0.01, Math.min(1, v));
        _pending = brightness;
        throttle.restart();
    }

    function flush() {
        if (_pending < 0) return;
        if (setter.running) { throttle.restart(); return; }
        setter.command = ["brightnessctl", "-q", "-c", "backlight", "set", Math.round(_pending * 100) + "%"];
        _pending = -1;
        setter.running = true;
    }

    Timer { id: throttle; interval: 50; onTriggered: root.flush() }

    Process {
        id: getter
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",");
                if (p.length >= 5 && parseInt(p[4]) > 0) {
                    root.brightnessAvailable = true;
                    if (!throttle.running) root.brightness = parseInt(p[2]) / parseInt(p[4]);
                } else {
                    root.brightnessAvailable = false;
                }
            }
        }
    }
    Process { id: setter }

    Process {
        id: sunset
        command: ["hyprsunset", "-t", String(Config.nightLightTemp)]
        running: root.nightLight
    }

    Component.onCompleted: refresh()
    Connections {
        target: UiState
        function onActiveChanged() { if (UiState.active === "quick") root.refresh(); }
    }
}

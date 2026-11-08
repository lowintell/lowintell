pragma Singleton
import QtQuick
import Quickshell

// Code-level settings. Anything the settings panel can change (weather, clock, workspaces, ...)
// is bound to Settings and saved in ~/.local/state/qs-glass/settings.json.
Singleton {
    // Weather (Open-Meteo, no API key). Change these three to relocate.
    property string weatherName: Settings.weatherName
    property real weatherLat: Settings.weatherLat
    property real weatherLon: Settings.weatherLon
    property bool useFahrenheit: Settings.useFahrenheit
    // Open-Meteo model. "" = automatic mix. Try: ecmwf_ifs025, icon_global, gfs_seamless, meteofrance_seamless
    property string weatherModel: Settings.weatherModel

    // Clock
    property string timeFormat: Settings.clock24 ? "HH:mm" : "h:mm AP"
    property string dateFormat: Settings.dateFormat

    // Hyprland >= 0.55 with a hyprland.lua config needs Lua dispatch syntax.
    // Set to false only if you still use the old hyprlang .conf.
    property bool hyprLua: true
    property int workspaceCount: Settings.workspaceCount

    // Audio visualizer. Point this at your own script to capture a single app only,
    // e.g. ["/home/you/.config/quickshell/firefox-cava.sh"].
    property var cavaCommand: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]

    // GPU polling (nvidia-smi / amdgpu sysfs). Only runs while the System panel is open,
    // because querying nvidia-smi can wake a hybrid-graphics dGPU.
    property bool gpuPolling: Settings.gpuPolling


    // tuned profiles shown in quick settings (name = tuned profile, shown only if it exists).
    // Laptop-friendly extras you can add: "balanced-battery", "laptop-battery-powersave", "latency-performance".
    property var tunedProfiles: [
        { name: "powersave", label: "Saver", icon: "eco" },
        { name: "balanced", label: "Balanced", icon: "balance" },
        { name: "throughput-performance", label: "Performance", icon: "bolt" }
    ]
    // If `tuned-adm profile` needs root on your system, set this to ["sudo", "-n"] (with a NOPASSWD rule) or ["doas", "-n"].
    property var tunedElevate: []

    property int nightLightTemp: Settings.nightLightTemp
    property string terminal: "kitty"
    property var lockCommand: ["hyprlock"]
    property var powerCommand: ["wlogout"]
}

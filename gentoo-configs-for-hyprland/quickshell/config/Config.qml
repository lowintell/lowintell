pragma Singleton
import QtQuick
import Quickshell

// User-editable settings. Everything here is read live.
Singleton {
    // Weather (Open-Meteo, no API key). Change these three to relocate.
    property string weatherName: "Beirut, Lebanon"
    property real weatherLat: 33.8938
    property real weatherLon: 35.5018
    property bool useFahrenheit: false
    // Open-Meteo model. "" = automatic mix. Try: ecmwf_ifs025, icon_global, gfs_seamless, meteofrance_seamless
    property string weatherModel: ""

    // Clock
    property string timeFormat: "HH:mm"
    property string dateFormat: "ddd d MMM"

    // Hyprland >= 0.55 with a hyprland.lua config needs Lua dispatch syntax.
    // Set to false only if you still use the old hyprlang .conf.
    property bool hyprLua: true
    property int workspaceCount: 5

    // Audio visualizer. Point this at your own script to capture a single app only,
    // e.g. ["/home/you/.config/quickshell/firefox-cava.sh"].
    property var cavaCommand: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]

    // GPU polling (nvidia-smi / amdgpu sysfs). Only runs while the System panel is open,
    // because querying nvidia-smi can wake a hybrid-graphics dGPU.
    property bool gpuPolling: true


    // tuned profiles shown in quick settings (name = tuned profile, shown only if it exists).
    // Laptop-friendly extras you can add: "balanced-battery", "laptop-battery-powersave", "latency-performance".
    property var tunedProfiles: [
        { name: "powersave", label: "Saver", icon: "eco" },
        { name: "balanced", label: "Balanced", icon: "balance" },
        { name: "throughput-performance", label: "Performance", icon: "bolt" }
    ]
    // If `tuned-adm profile` needs root on your system, set this to ["sudo", "-n"] (with a NOPASSWD rule) or ["doas", "-n"].
    property var tunedElevate: ["sudo", "-n"]

    property int nightLightTemp: 4200
    property string terminal: "kitty"
    property var lockCommand: ["hyprlock"]
    property var powerCommand: ["wlogout"]
}

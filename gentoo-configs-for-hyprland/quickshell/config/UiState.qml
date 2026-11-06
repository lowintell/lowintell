pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Which popup is open ("" | media | weather | system | quick | notifs | launcher).
Singleton {
    id: root

    property string active: ""
    readonly property var screen: pickScreen()

    function pickScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const list = Quickshell.screens;
        for (let i = 0; i < list.length; i++)
            if (list[i].name === name) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    function toggle(n) { active = (active === n) ? "" : n; }
    function open(n) { active = n; }
    function close() { active = ""; }

    // qs -c glass ipc call shell toggle launcher
    IpcHandler {
        target: "shell"
        function toggle(name: string): void { root.toggle(name); }
        function open(name: string): void { root.open(name); }
        function close(): void { root.close(); }
    }
}

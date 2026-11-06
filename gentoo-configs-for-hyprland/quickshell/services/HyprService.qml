pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// Compositor actions. Reading state (workspaces, focus) goes through Quickshell's
// Hyprland IPC module; dispatching uses hyprctl so it works with Lua configs (0.55+).
Singleton {
    function focusWorkspace(id) {
        if (Config.hyprLua)
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = "${id}" })`]);
        else
            Hyprland.dispatch("workspace " + id);
    }

    // dir: -1 previous, +1 next (existing workspaces)
    function cycleWorkspace(dir) {
        const sel = dir < 0 ? "e-1" : "e+1";
        focusWorkspace(sel);
    }
}

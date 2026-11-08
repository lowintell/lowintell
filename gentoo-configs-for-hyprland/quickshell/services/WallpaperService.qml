pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Sets the desktop wallpaper through awww / swaybg / a custom command.
// The last wallpaper path is also written to ~/.local/state/qs-glass/wallpaper so your Hyprland
// startup can restore it:  awww img "$(cat ~/.local/state/qs-glass/wallpaper)"
Singleton {
    id: root

    function set(path) {
        const b = Settings.wallpaperBackend;
        if (b === "awww") {
            Quickshell.execDetached(["awww", "img", path,
                "--transition-type", Settings.wallpaperTransition,
                "--transition-duration", "1.2",
                "--transition-fps", "60"]);
        } else if (b === "swaybg") {
            // start the new one first, then remove the old one, so there is no flash
            Quickshell.execDetached(["sh", "-c",
                "old=$(pgrep -x swaybg); swaybg -i \"$1\" -m fill >/dev/null 2>&1 & sleep 0.4; [ -n \"$old\" ] && kill $old",
                "sh", path]);
        } else {
            const cmd = Settings.wallpaperCommand.split("%f").join("\"$1\"");
            Quickshell.execDetached(["sh", "-c", cmd, "sh", path]);
        }
        Settings.set("lastWallpaper", path);
        lastFile.setText(path + "\n");
    }

    FileView {
        id: lastFile
        path: Settings.stateDir + "/wallpaper"
        printErrors: false
    }
}

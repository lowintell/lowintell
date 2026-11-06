import Quickshell
import QtQuick
import qs.components
import qs.modules

// Futuristic glass shell for Hyprland.
// Run:   qs -c glass          (or just `qs` if installed as ~/.config/quickshell/shell.qml)
// Debug: qs -c glass -vv      /   qs -c glass log
ShellRoot {
    Variants {
        model: Quickshell.screens
        TopBar {}
    }

    Scrim {}

    MusicPlayer {}
    Weather {}
    SystemMonitor {}
    QuickSettings {}
    NotificationCenter {}
    AppLauncher {}
    NotificationPopups {}
}

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config

// Invisible full-screen catcher that closes the open popup when you click elsewhere.
// Leaves the bar uncovered, except for the launcher, which dims the whole screen.
PanelWindow {
    id: win

    readonly property bool launcher: UiState.active === "launcher"

    screen: UiState.screen
    visible: UiState.active !== ""
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true; bottom: true }
    margins.top: launcher ? 0 : Theme.barMargin + Theme.barHeight

    WlrLayershell.namespace: "qsscrim"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: win.launcher ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: UiState.close()
    }
}

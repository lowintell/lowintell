import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config

// Base for every dropdown/popup: a layer-shell window that fades + slides a GlassPanel in and out.
// The window only exists on screen while open (or fading), and its input region is just the panel.
PanelWindow {
    id: win

    required property string name
    property int panelWidth: 380
    property int panelHeight: 300
    property string align: "right"      // right | left | center
    property bool keyboard: false
    property int topMargin: Theme.barMargin + Theme.barHeight + 8 - Theme.shadowPad
    default property alias content: glass.content

    readonly property bool open: UiState.active === name

    screen: UiState.screen
    visible: open || glass.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: panelWidth + Theme.shadowPad * 2
    implicitHeight: panelHeight + Theme.shadowPad * 2

    anchors {
        top: true
        left: win.align === "left"
        right: win.align === "right"
    }
    margins {
        top: win.topMargin
        left: Theme.barMargin - Theme.shadowPad
        right: Theme.barMargin - Theme.shadowPad
    }

    WlrLayershell.namespace: "qsglass-" + win.name
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: win.open && win.keyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region { item: glass }

    GlassPanel {
        id: glass
        x: Theme.shadowPad
        y: Theme.shadowPad
        width: win.panelWidth
        height: win.panelHeight
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: win.open ? 0 : -10
            Behavior on y { NumberAnimation { duration: Theme.animMed + 60; easing.type: Easing.OutCubic } }
        }
    }
}

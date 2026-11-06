import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config

// Glass-styled system-tray context menu. It is an overlay panel like the other popups, so the
// shared Scrim closes it on any outside click. Usage: trayMenu.openAt(iconItem, trayItem.menu)
PanelWindow {
    id: win

    required property var bar
    property var current: null
    property var stack: []
    property real menuX: 0
    readonly property int menuWidth: 250
    readonly property bool open: UiState.active === "tray"

    screen: bar.screen
    visible: open || glass.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: menuWidth + Theme.shadowPad * 2
    implicitHeight: col.implicitHeight + 16 + Theme.shadowPad * 2

    anchors { top: true; left: true }
    margins {
        top: Theme.barMargin + Theme.barHeight + 6 - Theme.shadowPad
        left: Math.max(0, win.menuX - Theme.shadowPad)
    }

    WlrLayershell.namespace: "qsglass-tray"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region { item: glass }

    function openAt(item, menuHandle) {
        if (!menuHandle) return;
        const p = item.mapToItem(bar.contentItem, 0, 0);
        const wanted = Theme.barMargin + p.x - 12;
        menuX = Math.max(8, Math.min(wanted, bar.screen.width - menuWidth - 8));
        stack = [];
        current = menuHandle;
        UiState.open("tray");
    }

    QsMenuOpener { id: opener; menu: win.current }

    GlassPanel {
        id: glass
        x: Theme.shadowPad
        y: Theme.shadowPad
        width: win.menuWidth
        height: col.implicitHeight + 16
        radius: Theme.radiusSm + 4
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: win.open ? 0 : -8
            Behavior on y { NumberAnimation { duration: Theme.animMed + 40; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            id: col
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 2

            // back row for submenus
            Rectangle {
                visible: win.stack.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 8
                color: backMa.containsMouse ? Theme.tileHover : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    spacing: 8
                    Icon { name: "arrow_back"; size: 16; color: Theme.textDim }
                    Text {
                        text: "Back"
                        color: Theme.textDim
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                    }
                }
                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const s = win.stack.slice();
                        win.current = s.pop();
                        win.stack = s;
                    }
                }
            }

            Repeater {
                model: opener.children
                delegate: Item {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.isSeparator ? 9 : 32

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: Theme.hairline
                    }

                    Rectangle {
                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        radius: 8
                        opacity: row.modelData.enabled ? 1 : 0.4
                        color: ma.containsMouse && row.modelData.enabled ? Theme.alpha(Theme.accent, 0.16) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Item {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                IconImage {
                                    anchors.fill: parent
                                    visible: row.modelData.icon !== "" && row.modelData.buttonType === 0
                                    source: row.modelData.icon
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    visible: row.modelData.buttonType !== 0 && row.modelData.checkState === 2
                                    name: "check"
                                    size: 16
                                    color: Theme.accent
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.text.replace(/&([^&])/g, "$1")
                                color: Theme.text
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Icon {
                                visible: row.modelData.hasChildren
                                name: "chevron_right"
                                size: 16
                                color: Theme.textDim
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: row.modelData.enabled
                            onClicked: {
                                if (row.modelData.hasChildren) {
                                    win.stack = win.stack.concat([win.current]);
                                    win.current = row.modelData;
                                } else {
                                    row.modelData.triggered();
                                    UiState.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

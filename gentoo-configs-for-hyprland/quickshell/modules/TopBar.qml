import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Three floating glass islands over a fully transparent bar window:
// left (launcher, workspaces, media/title), centre (clock + weather), right (tray, load, status, bell).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins { top: Theme.barMargin; left: Theme.barMargin; right: Theme.barMargin }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    WlrLayershell.namespace: "qsglass-bar"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region {
        Region { item: leftIsland }
        Region { item: centerIsland }
        Region { item: rightIsland }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    TrayMenu { id: trayMenu; bar: bar }

    // always show at least Config.workspaceCount dots, and grow to include the highest workspace in use
    readonly property int wsCount: {
        let m = Config.workspaceCount;
        const v = Hyprland.workspaces.values;
        for (let i = 0; i < v.length; i++) if (v[i].id > m) m = v[i].id;
        return m;
    }

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: bat !== null && bat.isLaptopBattery
    readonly property real batPct: hasBat ? bat.percentage : 0
    readonly property bool charging: hasBat && bat.state === UPowerDeviceState.Charging
    readonly property string batIcon: {
        if (charging) return "battery_charging_full";
        if (batPct > 0.9) return "battery_full";
        if (batPct > 0.7) return "battery_6_bar";
        if (batPct > 0.5) return "battery_4_bar";
        if (batPct > 0.3) return "battery_3_bar";
        if (batPct > 0.15) return "battery_2_bar";
        return "battery_alert";
    }
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter !== null && btAdapter.enabled

    // ───────────── left island ─────────────
    GlassPanel {
        id: leftIsland
        anchors.left: parent.left
        height: parent.height
        width: leftRow.implicitWidth + 20
        radius: 14
        fill: Theme.glassBar
        shadowStrength: 0.5

        RowLayout {
            id: leftRow
            anchors.centerIn: parent
            spacing: 10

            GentooLogo { Layout.preferredWidth: 22; Layout.preferredHeight: 22; Layout.leftMargin: 4 }

            // workspaces
            Item {
                Layout.preferredWidth: wsRow.implicitWidth
                Layout.preferredHeight: 20
                Row {
                    id: wsRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7
                    Repeater {
                        model: bar.wsCount
                        delegate: Rectangle {
                            id: dot
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                            readonly property bool occupied: {
                                const v = Hyprland.workspaces.values;
                                for (let i = 0; i < v.length; i++) if (v[i].id === wsId) return true;
                                return false;
                            }
                            width: focused ? 28 : 10
                            height: 10
                            radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            color: focused ? Theme.accent : (occupied ? Theme.textDim : Theme.alpha(Theme.textMute, 0.45))
                            Behavior on width { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: Theme.animMed } }

                            Rectangle {
                                z: -1
                                anchors.centerIn: parent
                                width: parent.width + 8
                                height: 16
                                radius: 8
                                color: Theme.alpha(Theme.accent, 0.20)
                                opacity: dot.focused ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: HyprService.focusWorkspace(dot.wsId)
                            }
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onWheel: w => HyprService.cycleWorkspace(w.angleDelta.y > 0 ? -1 : 1)
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 16; color: Theme.hairline }

            // now playing chip
            BarButton {
                visible: MediaService.hasPlayer
                active: UiState.active === "media"
                onClicked: m => {
                    if (m.button === Qt.MiddleButton) MediaService.toggle();
                    else UiState.toggle("media");
                }
                Visualizer { Layout.preferredWidth: 24; Layout.preferredHeight: 14; bars: 5; gap: 2 }
                Text {
                    Layout.maximumWidth: 230
                    text: MediaService.artist !== "" ? MediaService.title + "  ·  " + MediaService.artist : MediaService.title
                    color: Theme.text
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            // active window title
            Text {
                visible: ToplevelManager.activeToplevel !== null && (!MediaService.hasPlayer || bar.width > 1800)
                Layout.maximumWidth: 260
                text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
                color: Theme.textMute
                font.family: Theme.fontSans
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    // ───────────── centre island ─────────────
    GlassPanel {
        id: centerIsland
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        width: centerBtn.implicitWidth + 20
        radius: 14
        fill: Theme.glassBar
        shadowStrength: 0.5

        BarButton {
            id: centerBtn
            anchors.centerIn: parent
            active: UiState.active === "weather"
            onClicked: UiState.toggle("weather")
            spacing: 10

            Text {
                text: Qt.formatDateTime(clock.date, Config.timeFormat)
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                text: Qt.formatDateTime(clock.date, Config.dateFormat)
                color: Theme.textDim
                font.family: Theme.fontSans
                font.pixelSize: 12
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 14; color: Theme.hairline }
            WeatherIcon {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                kind: WeatherService.kind
                isDay: WeatherService.isDay
                opacity: WeatherService.ready ? 1 : 0.3
            }
            Text {
                text: WeatherService.ready ? Math.round(WeatherService.temp) + "°" : "--"
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 13
            }
        }
    }

    // ───────────── right island ─────────────
    GlassPanel {
        id: rightIsland
        anchors.right: parent.right
        height: parent.height
        width: rightRow.implicitWidth + 20
        radius: 14
        fill: Theme.glassBar
        shadowStrength: 0.5

        RowLayout {
            id: rightRow
            anchors.centerIn: parent
            spacing: 6

            // system tray
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    id: trayItem
                    required property var modelData
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: trayMa.containsMouse ? Theme.tileHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: trayItem.modelData.icon
                    }
                    MouseArea {
                        id: trayMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: m => {
                            const it = trayItem.modelData;
                            if (m.button === Qt.LeftButton && !it.onlyMenu) {
                                it.activate();
                            } else if (m.button === Qt.MiddleButton) {
                                it.secondaryActivate();
                            } else if (it.hasMenu) {
                                trayMenu.openAt(trayItem, it.menu);
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: SystemTray.items.values.length > 0
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.hairline
            }

            // CPU / RAM
            BarButton {
                active: UiState.active === "system"
                onClicked: UiState.toggle("system")
                spacing: 5
                Icon { name: "memory"; size: 15; color: Theme.accent2 }
                Text {
                    text: Math.round(SystemService.cpu) + "%"
                    color: Theme.text
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    Layout.preferredWidth: 30
                }
                Icon { name: "data_usage"; size: 15; color: Theme.violet }
                Text {
                    text: Math.round(SystemService.ram) + "%"
                    color: Theme.text
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    Layout.preferredWidth: 30
                }
            }

            // network / bluetooth / volume / battery  → quick settings
            BarButton {
                active: UiState.active === "quick"
                onClicked: UiState.toggle("quick")
                onScrolled: d => AudioService.setVolume(AudioService.volume + (d > 0 ? 0.03 : -0.03))
                spacing: 8

                Icon {
                    name: NetworkService.icon
                    size: 16
                    color: NetworkService.connected ? Theme.text : Theme.textMute
                }
                Icon { visible: bar.btOn; name: "bluetooth"; size: 16; color: Theme.accent }
                RowLayout {
                    spacing: 3
                    Icon { name: AudioService.icon; size: 16; color: AudioService.muted ? Theme.textMute : Theme.text }
                    Text {
                        text: Math.round(AudioService.volume * 100) + "%"
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                    }
                }
                RowLayout {
                    visible: bar.hasBat
                    spacing: 3
                    Icon {
                        name: bar.batIcon
                        size: 17
                        color: bar.charging ? Theme.good : (bar.batPct <= 0.15 ? Theme.bad : Theme.text)
                    }
                    Text {
                        text: Math.round(bar.batPct * 100) + "%"
                        color: bar.batPct <= 0.15 && !bar.charging ? Theme.bad : Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                    }
                }
            }

            // notifications
            BarButton {
                active: UiState.active === "notifs"
                onClicked: UiState.toggle("notifs")
                Item {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Icon {
                        anchors.centerIn: parent
                        name: NotificationService.dnd ? "notifications_off" : "notifications"
                        size: 17
                        color: NotificationService.dnd ? Theme.textMute : Theme.text
                    }
                    Rectangle {
                        visible: NotificationService.count > 0 && !NotificationService.dnd
                        width: 7; height: 7; radius: 4
                        anchors { right: parent.right; top: parent.top; rightMargin: -1; topMargin: 0 }
                        color: Theme.accent2
                    }
                }
            }
        }
    }
}

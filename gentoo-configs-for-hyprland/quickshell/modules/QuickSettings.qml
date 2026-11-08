import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

PanelPopup {
    id: win

    name: "quick"
    align: "right"
    panelWidth: 390
    panelHeight: col.implicitHeight + Theme.pad * 2

    property bool showNetworks: false
    onOpenChanged: if (!open) showNetworks = false

    // bluetooth helpers
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter !== null && adapter.enabled
    function btPct(dev) {
        const b = dev.battery;
        return Math.round(b <= 1 ? b * 100 : b);
    }
    function btIcon(dev) {
        const i = (dev.icon || "").toLowerCase();
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "headphones";
        if (i.indexOf("mouse") >= 0) return "mouse";
        if (i.indexOf("keyboard") >= 0) return "keyboard";
        if (i.indexOf("phone") >= 0) return "smartphone";
        if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0) return "sports_esports";
        if (i.indexOf("audio") >= 0 || i.indexOf("speaker") >= 0) return "speaker";
        return "bluetooth_connected";
    }
    readonly property var btConnected: {
        if (!adapter || !adapter.enabled) return [];
        const list = Bluetooth.devices.values, out = [];
        for (let i = 0; i < list.length; i++) if (list[i].connected) out.push(list[i]);
        return out;
    }
    readonly property string btSubtitle: {
        if (!adapter) return "Unavailable";
        if (!adapter.enabled) return "Off";
        if (btConnected.length === 0) return "On";
        return btConnected.map(d => d.name + (d.batteryAvailable ? " · " + btPct(d) + "%" : "")).join(", ");
    }

    // tuned profiles that actually exist on this machine
    readonly property var profileModel: {
        const have = TunedService.available;
        return Config.tunedProfiles.filter(p => have.indexOf(p.name) >= 0);
    }

    // battery helpers
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: bat !== null && bat.isLaptopBattery
    readonly property real batPct: hasBat ? bat.percentage : 0
    readonly property bool charging: hasBat && bat.state === UPowerDeviceState.Charging
    function fmtTime(sec) {
        if (!sec || sec <= 0) return "";
        const h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }
    readonly property string batText: {
        if (!hasBat) return "";
        if (bat.state === UPowerDeviceState.FullyCharged) return "Fully charged";
        if (charging) { const t = fmtTime(bat.timeToFull); return t !== "" ? "Charging · " + t + " to full" : "Charging"; }
        const t = fmtTime(bat.timeToEmpty);
        return t !== "" ? t + " remaining" : "On battery";
    }

    ColumnLayout {
        id: col
        x: Theme.pad
        y: Theme.pad
        width: parent.width - Theme.pad * 2
        spacing: 12

        // header
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: "Quick settings"
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            IconButton {
                size: 32; iconSize: 17; icon: "settings"
                onClicked: UiState.open("settings")
            }
            IconButton {
                size: 32; iconSize: 17; icon: "lock"
                onClicked: { UiState.close(); Quickshell.execDetached(Config.lockCommand); }
            }
            IconButton {
                size: 32; iconSize: 17; icon: "power_settings_new"; iconColor: Theme.bad
                onClicked: { UiState.close(); Quickshell.execDetached(Config.powerCommand); }
            }
        }

        // sliders
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: sliders.implicitHeight + 24
            radius: Theme.radiusSm + 2
            color: Theme.tile
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: sliders
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    IconButton {
                        size: 30; iconSize: 19
                        icon: AudioService.icon
                        iconColor: AudioService.muted ? Theme.textMute : Theme.accent
                        onClicked: AudioService.toggleMute()
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        GlassSlider {
                            Layout.fillWidth: true
                            value: AudioService.volume
                            opacity: AudioService.muted ? 0.45 : 1
                            onMoved: v => AudioService.setVolume(v)
                        }
                        Text {
                            Layout.fillWidth: true
                            text: AudioService.deviceName
                            color: Theme.textMute
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(AudioService.volume * 100) + "%"
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: DisplayService.brightnessAvailable
                    spacing: 10
                    Item {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        Icon { anchors.centerIn: parent; name: "brightness_6"; size: 19; color: Theme.accent2 }
                    }
                    GlassSlider {
                        Layout.fillWidth: true
                        tint: Theme.accent2
                        value: DisplayService.brightness
                        onMoved: v => DisplayService.setBrightness(v)
                    }
                    Text {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(DisplayService.brightness * 100) + "%"
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                    }
                }
            }
        }

        // toggles
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: NetworkService.icon
                title: "Wi-Fi"
                subtitle: NetworkService.wifiEnabled ? (NetworkService.kind === "wifi" ? NetworkService.ssid : NetworkService.label) : "Off"
                active: NetworkService.wifiEnabled
                onClicked: NetworkService.setWifi(!NetworkService.wifiEnabled)
                onRightClicked: win.showNetworks = !win.showNetworks
            }
            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: win.btOn ? "bluetooth" : "bluetooth_disabled"
                title: "Bluetooth"
                subtitle: win.btSubtitle
                active: win.btOn
                enabledTile: win.adapter !== null
                onClicked: if (win.adapter) win.adapter.enabled = !win.adapter.enabled
            }
            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "nightlight"
                title: "Night light"
                subtitle: DisplayService.nightLight ? Config.nightLightTemp + " K" : "Off"
                active: DisplayService.nightLight
                onClicked: DisplayService.nightLight = !DisplayService.nightLight
            }
            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: NotificationService.dnd ? "notifications_off" : "notifications"
                title: "Do not disturb"
                subtitle: NotificationService.dnd ? "On" : "Off"
                active: NotificationService.dnd
                onClicked: NotificationService.dnd = !NotificationService.dnd
            }
        }

        // connected bluetooth devices with battery level
        Rectangle {
            Layout.fillWidth: true
            visible: win.btConnected.length > 0
            implicitHeight: btCol.implicitHeight + 24
            radius: Theme.radiusSm + 2
            color: Theme.tile
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: btCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10

                Repeater {
                    model: win.btConnected
                    delegate: RowLayout {
                        id: dev
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        Icon { name: win.btIcon(dev.modelData); size: 19; color: Theme.accent }
                        Text {
                            Layout.fillWidth: true
                            text: dev.modelData.name
                            color: Theme.text
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            visible: dev.modelData.batteryAvailable
                            spacing: 8
                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.09)
                                Rectangle {
                                    width: parent.width * Math.min(1, win.btPct(dev.modelData) / 100)
                                    height: parent.height
                                    radius: 3
                                    color: win.btPct(dev.modelData) <= 20 ? Theme.bad : Theme.accent
                                    Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                                }
                            }
                            Text {
                                Layout.preferredWidth: 34
                                horizontalAlignment: Text.AlignRight
                                text: win.btPct(dev.modelData) + "%"
                                color: win.btPct(dev.modelData) <= 20 ? Theme.bad : Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                            }
                        }
                        Text {
                            visible: !dev.modelData.batteryAvailable
                            text: "no battery info"
                            color: Theme.textMute
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // wi-fi networks (right-click the Wi-Fi tile, or use the chevron)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: netCol.implicitHeight + 16
            radius: Theme.radiusSm + 2
            color: Theme.tile
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: netCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                spacing: 2

                MouseArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.showNetworks = !win.showNetworks
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        Icon { name: NetworkService.icon; size: 16; color: Theme.accent }
                        Text {
                            Layout.fillWidth: true
                            text: NetworkService.label
                            color: Theme.text
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: NetworkService.kind === "wifi"
                            text: NetworkService.signal + "%"
                            color: Theme.textMute
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                        Icon {
                            name: "keyboard_arrow_down"
                            size: 18
                            color: Theme.textDim
                            rotation: win.showNetworks ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                Repeater {
                    model: win.showNetworks ? NetworkService.networks.slice(0, 6) : []
                    delegate: Rectangle {
                        id: net
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: netMa.containsMouse ? Theme.tileHover : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Icon {
                                name: net.modelData.signal > 66 ? "wifi" : (net.modelData.signal > 33 ? "wifi_2_bar" : "wifi_1_bar")
                                size: 15
                                color: net.modelData.inUse ? Theme.accent : Theme.textDim
                            }
                            Text {
                                Layout.fillWidth: true
                                text: net.modelData.ssid
                                color: net.modelData.inUse ? Theme.accent : Theme.text
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Icon { visible: net.modelData.secure; name: "lock"; size: 13; color: Theme.textMute }
                        }
                        MouseArea {
                            id: netMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (!net.modelData.inUse) NetworkService.connectTo(net.modelData.ssid)
                        }
                    }
                }
            }
        }

        // power profiles (tuned)
        RowLayout {
            Layout.fillWidth: true
            visible: profileModel.length > 0
            spacing: 6

            Repeater {
                model: win.profileModel
                delegate: Rectangle {
                    id: prof
                    required property var modelData
                    readonly property bool on: TunedService.active === modelData.name
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 40
                    radius: Theme.radiusSm
                    color: on ? Theme.alpha(Theme.accent, 0.18) : (profMa.containsMouse ? Theme.tileHover : Theme.tile)
                    border.width: 1
                    border.color: on ? Theme.alpha(Theme.accent, 0.55) : Theme.hairline
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Icon { name: prof.modelData.icon; size: 16; color: prof.on ? Theme.accent : Theme.textDim }
                        Text {
                            text: prof.modelData.label
                            color: prof.on ? Theme.text : Theme.textDim
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        id: profMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TunedService.set(prof.modelData.name)
                    }
                }
            }
        }
        Text {
            visible: TunedService.failed
            Layout.fillWidth: true
            text: "Couldn't switch profile (tuned-adm needs permission). See tunedElevate in Config.qml."
            color: Theme.bad
            font.family: Theme.fontSans
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        // battery
        Rectangle {
            Layout.fillWidth: true
            visible: win.hasBat
            implicitHeight: 64
            radius: Theme.radiusSm + 2
            color: Theme.tile
            border.width: 1
            border.color: Theme.hairline

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                Icon {
                    name: win.charging ? "battery_charging_full" : "battery_full"
                    size: 26
                    color: win.charging ? Theme.good : (win.batPct <= 0.15 ? Theme.bad : Theme.accent)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Math.round(win.batPct * 100) + "%"
                            color: Theme.text
                            font.family: Theme.fontMono
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: win.batText
                            color: Theme.textMute
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.08)
                        Rectangle {
                            width: parent.width * win.batPct
                            height: parent.height
                            radius: 3
                            color: win.charging ? Theme.good : (win.batPct <= 0.15 ? Theme.bad : Theme.accent)
                            Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

// Settings window with tabs. Everything saves automatically to ~/.local/state/qs-glass/settings.json.
PanelPopup {
    id: win

    name: "settings"
    align: "center"
    keyboard: true
    panelWidth: 680
    panelHeight: 640
    topMargin: Theme.barMargin + Theme.barHeight + 12 - Theme.shadowPad

    property int tab: 0
    readonly property var tabs: [
        { label: "General", icon: "tune" },
        { label: "Appearance", icon: "palette" },
        { label: "Colors", icon: "colorize" },
        { label: "Media", icon: "music_note" },
        { label: "Apps", icon: "sync_alt" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Icon { name: "settings"; size: 20; color: Theme.accent }
            Text {
                text: "Settings"
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            IconButton { size: 30; iconSize: 17; icon: "close"; iconColor: Theme.textDim; onClicked: UiState.close() }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: win.tabs
                delegate: Rectangle {
                    id: tabBtn
                    required property var modelData
                    required property int index
                    readonly property bool on: win.tab === index
                    height: 34
                    width: tabRow.implicitWidth + 28
                    radius: 10
                    color: on ? Theme.alpha(Theme.accent, 0.22) : (tabMa.containsMouse ? Theme.tileHover : "transparent")
                    border.width: on ? 1 : 0
                    border.color: Theme.alpha(Theme.accent, 0.6)
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 7
                        Icon { name: tabBtn.modelData.icon; size: 17; color: tabBtn.on ? Theme.accent : Theme.textDim }
                        Text {
                            text: tabBtn.modelData.label
                            color: tabBtn.on ? Theme.text : Theme.textDim
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            font.weight: tabBtn.on ? Font.DemiBold : Font.Normal
                        }
                    }
                    MouseArea { id: tabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.tab = tabBtn.index }
                }
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hairline }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: win.tab

            SettingsGeneral {}
            SettingsAppearance {}
            SettingsColors { active: win.open && win.tab === 2 }
            SettingsMedia {}
            SettingsApps {}
        }
    }
}

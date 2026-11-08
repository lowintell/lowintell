import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

ScrollTab {
    SettingsCard {
        title: "Player style"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    { value: "circle", title: "Circular", desc: "Round album art with a visualizer ring around it", icon: "album" },
                    { value: "classic", title: "Classic", desc: "Square art, track info and controls side by side", icon: "queue_music" }
                ]
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool on: Settings.mediaStyle === modelData.value
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: cardCol.implicitHeight + 28
                    radius: Theme.radiusSm + 2
                    color: on ? Theme.alpha(Theme.accent, 0.16) : (ma.containsMouse ? Theme.tileHover : Qt.rgba(1, 1, 1, 0.04))
                    border.width: 1
                    border.color: on ? Theme.alpha(Theme.accent, 0.7) : Theme.hairline
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animMed } }

                    ColumnLayout {
                        id: cardCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        spacing: 8
                        RowLayout {
                            spacing: 8
                            Icon { name: card.modelData.icon; size: 22; color: card.on ? Theme.accent : Theme.textDim }
                            Text {
                                text: card.modelData.title
                                color: Theme.text
                                font.family: Theme.fontSans
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Icon { visible: card.on; name: "check_circle"; size: 18; color: Theme.accent }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.desc
                            color: Theme.textMute
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.set("mediaStyle", card.modelData.value)
                    }
                }
            }
        }
    }

    SettingsCard {
        title: "Visualizer"

        SettingRow {
            label: "Audio visualizer"
            desc: "Turns cava off completely when disabled (saves a little CPU)"
            ToggleSwitch { checked: Settings.visualizerEnabled; onToggled: v => Settings.set("visualizerEnabled", v) }
        }
        SliderRow {
            label: "Ring bars"
            from: 24; to: 96; step: 4
            value: Settings.radialBars
            onMoved: v => Settings.set("radialBars", v)
        }
        SettingRow {
            label: "Spin album art"
            desc: "Slowly rotates the round art while playing"
            ToggleSwitch { checked: Settings.spinArt; onToggled: v => Settings.set("spinArt", v) }
        }
    }
}

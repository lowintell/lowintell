import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

PanelPopup {
    id: win

    name: "media"
    align: "left"
    panelWidth: 430
    panelHeight: col.implicitHeight + Theme.pad * 2

    ColumnLayout {
        id: col
        x: Theme.pad
        y: Theme.pad
        width: parent.width - Theme.pad * 2
        spacing: 14

        // empty state
        ColumnLayout {
            visible: !MediaService.hasPlayer
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            spacing: 8
            Item { Layout.fillHeight: true }
            Icon { Layout.alignment: Qt.AlignHCenter; name: "music_off"; size: 40; color: Theme.textMute }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Nothing playing"
                color: Theme.textDim
                font.family: Theme.fontSans
                font.pixelSize: 14
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Start Spotify, Firefox, mpv… anything with MPRIS"
                color: Theme.textMute
                font.family: Theme.fontSans
                font.pixelSize: 11
            }
            Item { Layout.fillHeight: true }
        }

        // header: art + metadata
        RowLayout {
            visible: MediaService.hasPlayer
            Layout.fillWidth: true
            spacing: 16

            Item {
                Layout.preferredWidth: 124
                Layout.preferredHeight: 124

                Rectangle {
                    id: ring
                    property real pulse: 0.4
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 18
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.alpha(Theme.accent, 0.6)
                    opacity: MediaService.isPlaying ? pulse : 0.2
                    Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                    SequentialAnimation on pulse {
                        running: win.open && MediaService.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.35; duration: 1500; easing.type: Easing.InOutSine }
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 15
                    color: Theme.surface
                    Image {
                        id: art
                        anchors.fill: parent
                        source: MediaService.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        sourceSize: Qt.size(320, 320)
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        name: "music_note"
                        size: 44
                        color: Theme.textMute
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: MediaService.title
                    color: Theme.text
                    font.family: Theme.fontSans
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: MediaService.artist
                    color: Theme.accent
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: MediaService.album
                    color: Theme.textMute
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                Item { Layout.preferredHeight: 4 }
                RowLayout {
                    spacing: 10
                    BarButton {
                        enabled: MediaService.playerCount > 1
                        onClicked: MediaService.cycle()
                        Icon { name: "graphic_eq"; size: 14; color: Theme.textDim }
                        Text {
                            text: MediaService.identity + (MediaService.playerCount > 1 ? "  ⇄" : "")
                            color: Theme.textDim
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                        }
                    }
                    Visualizer {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 20
                        bars: 12
                        gap: 2
                    }
                }
            }
        }

        // progress
        ColumnLayout {
            visible: MediaService.hasPlayer
            Layout.fillWidth: true
            spacing: 0
            GlassSlider {
                Layout.fillWidth: true
                value: MediaService.length > 0 ? MediaService.position / MediaService.length : 0
                opacity: MediaService.canSeek ? 1 : 0.5
                onMoved: v => MediaService.seek(v * MediaService.length)
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: MediaService.fmt(MediaService.position)
                    color: Theme.textMute
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: MediaService.length > 0 ? MediaService.fmt(MediaService.length) : "live"
                    color: Theme.textMute
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }

        // transport + volume
        RowLayout {
            visible: MediaService.hasPlayer
            Layout.fillWidth: true
            spacing: 10

            Item { Layout.fillWidth: true }
            IconButton {
                icon: "skip_previous"
                size: 42
                iconSize: 24
                opacity: MediaService.canPrev ? 1 : 0.4
                onClicked: MediaService.previous()
            }
            Item {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                scale: playMa.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: width / 2
                    color: Theme.alpha(Theme.accent, MediaService.isPlaying ? 0.20 : 0.08)
                    Behavior on color { ColorAnimation { duration: Theme.animMed } }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 28
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: Theme.accent2 }
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: MediaService.isPlaying ? "pause" : "play_arrow"
                        size: 30
                        color: Theme.bg0
                    }
                }
                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MediaService.toggle()
                }
            }
            IconButton {
                icon: "skip_next"
                size: 42
                iconSize: 24
                opacity: MediaService.canNext ? 1 : 0.4
                onClicked: MediaService.next()
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            visible: MediaService.hasPlayer && MediaService.volumeSupported
            Layout.fillWidth: true
            spacing: 10
            Icon { name: MediaService.volume <= 0 ? "volume_mute" : "volume_up"; size: 18; color: Theme.textDim }
            GlassSlider {
                Layout.fillWidth: true
                value: MediaService.volume
                onMoved: v => MediaService.setVolume(v)
            }
            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: Math.round(MediaService.volume * 100) + "%"
                color: Theme.textMute
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }
    }
}

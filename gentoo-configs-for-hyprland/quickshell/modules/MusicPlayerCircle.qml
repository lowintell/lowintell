import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Circular player: round album art in the centre, a radial audio visualizer around it.
PanelPopup {
    id: win

    name: "media"
    enabledWhen: Settings.mediaStyle === "circle"
    align: "center"
    panelWidth: 400
    panelHeight: col.implicitHeight + Theme.pad * 2

    readonly property int artSize: 172

    ColumnLayout {
        id: col
        x: Theme.pad
        y: Theme.pad
        width: parent.width - Theme.pad * 2
        spacing: 10

        // ── hero: visualizer ring + round art ──
        Item {
            id: hero
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 290
            Layout.preferredHeight: 290

            RadialVisualizer {
                anchors.fill: parent
                visible: Settings.visualizerEnabled && MediaService.hasPlayer
                running: win.open
                playing: MediaService.isPlaying
                bars: Settings.radialBars
                innerRadius: win.artSize / 2 + 15
                maxLength: 42
            }

            // glow ring
            Rectangle {
                id: ring
                property real pulse: 0.4
                anchors.centerIn: parent
                width: win.artSize + 10
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.alpha(Theme.accent, 0.65)
                opacity: MediaService.isPlaying ? pulse : 0.25
                Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                SequentialAnimation on pulse {
                    running: win.open && MediaService.isPlaying
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.35; duration: 1500; easing.type: Easing.InOutSine }
                }
            }

            ClippingRectangle {
                id: art
                anchors.centerIn: parent
                width: win.artSize
                height: width
                radius: width / 2
                color: Theme.surface

                Image {
                    id: artImg
                    anchors.fill: parent
                    source: MediaService.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize: Qt.size(400, 400)
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                }
                Icon {
                    anchors.centerIn: parent
                    visible: artImg.status !== Image.Ready
                    name: MediaService.hasPlayer ? "music_note" : "music_off"
                    size: 52
                    color: Theme.textMute
                }

                NumberAnimation {
                    id: spin
                    target: art
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 24000
                    loops: Animation.Infinite
                    running: Settings.spinArt && win.open
                    paused: !MediaService.isPlaying
                    onRunningChanged: if (!running) art.rotation = 0
                }
            }

            // hover play/pause overlay (does not spin)
            Rectangle {
                anchors.centerIn: parent
                width: win.artSize
                height: width
                radius: width / 2
                color: "#000000"
                opacity: heroMa.containsMouse && MediaService.hasPlayer ? 0.45 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                Icon {
                    anchors.centerIn: parent
                    name: MediaService.isPlaying ? "pause" : "play_arrow"
                    size: 56
                    color: "#ffffff"
                }
            }
            MouseArea {
                id: heroMa
                anchors.centerIn: parent
                width: win.artSize
                height: width
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaService.toggle()
            }
        }

        // ── empty state ──
        Text {
            visible: !MediaService.hasPlayer
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing playing"
            color: Theme.textDim
            font.family: Theme.fontSans
            font.pixelSize: 14
        }

        // ── title / artist ──
        ColumnLayout {
            visible: MediaService.hasPlayer
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: MediaService.title
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 18
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: MediaService.artist
                color: Theme.accent
                font.family: Theme.fontSans
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: MediaService.album
                color: Theme.textMute
                font.family: Theme.fontSans
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            BarButton {
                Layout.alignment: Qt.AlignHCenter
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
        }

        // ── progress ──
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

        // ── transport ──
        RowLayout {
            visible: MediaService.hasPlayer
            Layout.fillWidth: true
            spacing: 14
            Item { Layout.fillWidth: true }
            IconButton {
                icon: "skip_previous"
                size: 42
                iconSize: 24
                opacity: MediaService.canPrev ? 1 : 0.4
                onClicked: MediaService.previous()
            }
            Item {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
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
                    radius: 27
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

        // ── volume ──
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

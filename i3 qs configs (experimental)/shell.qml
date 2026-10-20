// Quickshell for i3 — "Slate Tide" islands
//
// Three floating pills: [ workspaces + window title ]  [ clock / now-playing ]  [ status ]
// Built to feel snappy: everything is event-driven (i3 events, D-Bus, one tiny stats loop), nothing on the bar
// animates, there are no shadows (picom draws them), and cava only runs while a song plays.
//
// Needs: JetBrainsMono Nerd Font, picom (for the translucent/rounded look), cava, pipewire-pulse (parec/pactl),
//        bluez (bluetooth), i3-nagbar (comes with i3). Optional: yt-dlp (fetches SoundCloud covers).
// Icons are \uXXXX escapes (Font Awesome 4 codepoints) so they survive copy/paste.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Bluetooth
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

ShellRoot {
    id: root

    // ───────────── palette ─────────────
    readonly property color bgBase:    "#11121f"
    readonly property color slate:     "#2d3050"
    readonly property color slateHi:   "#4a5080"
    readonly property color mist:      "#7d85b5"
    readonly property color horizon:   "#b4bde8"
    readonly property color fgPrimary: "#d5daf2"
    readonly property color fgMuted:   "#8a90b8"
    readonly property color fgDim:     "#6a70a0"
    readonly property color amber:     "#d1a56b"
    readonly property color red:       "#e0645c"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property real uiScale: 1.2            // <- the one size knob: 1.0 small, 1.2 default, 1.5 big
    function s(v) { return Math.round(v * uiScale); }
    readonly property int fontSize: s(12)
    readonly property int barHeight: s(34)
    readonly property int workspaceCount: 5        // always show at least this many workspace buttons

    // ───────────── live data ─────────────
    property real cpuUsage: 0
    property real memUsage: 0
    property real wifiQuality: 0
    property real prevTotal: 0
    property real prevIdle: 0

    property var cavaBars: []          // full cava feed (popup)
    property bool cavaActive: false
    property int cavaFlat: 0
    property var miniBars: []          // light cava feed (little equalizer in the bar)
    property bool blinkOff: false
    property bool showDate: false
    property string winTitle: ""       // focused window title, from i3 events

    // ───────────── popups (one open at a time) ─────────────
    property bool mediaOpen: false
    property bool btOpen: false
    property bool trayMenuOpen: false
    property var trayMenuHandle: null
    property var trayMenuStack: []
    property bool closePending: false  // focus moved away: popups will close after a few seconds
    property bool popupHovered: false  // pointer is over a popup (holds the countdown)
    property real popupX: 0            // where the clicked trigger is, so the popup centres under it
    property string popupScreen: ""
    readonly property bool anyPopup: mediaOpen || btOpen || trayMenuOpen

    function closeAllPopups() {
        mediaOpen = false;
        btOpen = false;
        trayMenuOpen = false;
        closePending = false;
        popupHovered = false;
    }
    function openPopup(kind, screenName, x) {
        const same = (kind === "media" && mediaOpen) || (kind === "bt" && btOpen);
        closeAllPopups();
        if (same) return;                          // clicking the trigger again closes it
        popupScreen = screenName;
        popupX = x;
        popupAge.restart();
        if (kind === "media") mediaOpen = true;
        else if (kind === "bt") btOpen = true;
    }
    function openTrayMenu(item, screenName, x) {
        closeAllPopups();
        trayMenuStack = [];
        trayMenuHandle = item.menu;
        popupScreen = screenName;
        popupX = x;
        popupAge.restart();
        trayMenuOpen = true;
    }

    // X11 has no reliable "click outside" grab for popups. Instead: when focus moves to another window (or you
    // switch workspace), a 5 second countdown starts and the popup closes — unless the pointer is on it, which
    // holds the countdown (it starts over once you leave). Clicking the same trigger again also closes it.
    Timer { id: popupAge; interval: 350 }            // grace period right after opening
    Timer {
        id: closeTimer
        interval: 5000
        running: root.closePending && root.anyPopup && !root.popupHovered
        onTriggered: root.closeAllPopups()
    }

    // Two cava feeds:
    //   light (10 bars @15fps) — drives the little bar equalizer, runs while a song plays
    //   full  (20 bars @25fps) — drives the popup bars; runs ONLY while the popup is open and dies the moment it closes
    readonly property bool fullWanted: playing && mediaOpen
    onFullWantedChanged: {
        cavaFlat = 0;
        cavaProc.running = fullWanted;
        if (!fullWanted) { cavaActive = false; cavaBars = []; }
    }
    onMediaOpenChanged: artDebounce.restart()
    onPlayingChanged: {
        miniProc.running = playing;
        if (!playing) { miniBars = []; cavaProc.running = false; cavaActive = false; cavaBars = []; cavaFlat = 0; }
    }
    Component.onCompleted: if (playing) miniProc.running = true

    // ───────────── audio output / battery / clock ─────────────
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat ? bat.isLaptopBattery : false
    readonly property int batPct: bat ? Math.round(bat.percentage * 100) : 0
    readonly property bool batCharging: bat ? bat.state === UPowerDeviceState.Charging : false
    readonly property bool batCritical: hasBattery && !batCharging && batPct <= 15
    readonly property bool batWarning: hasBattery && !batCharging && batPct <= 30

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // power menu (i3-nagbar ships with i3): each button runs the command after it
    readonly property string i3PowerCmd:
        "i3-nagbar -t warning -m 'Power menu' -B 'Power off' 'systemctl poweroff' -B 'Reboot' 'systemctl reboot' -B 'Log out' 'i3-msg exit'"

    function volumeIcon() {
        if (muted || volume <= 0.001) return "\uf026";
        if (volume < 0.34) return "\uf026";
        if (volume < 0.67) return "\uf027";
        return "\uf028";
    }
    function batteryIcon() {
        if (batCharging) return "\uf0e7";
        if (batPct > 87) return "\uf240";
        if (batPct > 62) return "\uf241";
        if (batPct > 37) return "\uf242";
        if (batPct > 12) return "\uf243";
        return "\uf244";
    }
    function setVolume(v) {
        if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    Timer {                                   // blinks the battery only while critical
        interval: 700
        repeat: true
        running: root.batCritical
        onTriggered: root.blinkOff = !root.blinkOff
        onRunningChanged: if (!running) root.blinkOff = false
    }

    // ───────────── i3: workspaces + focused window title ─────────────
    function i3FocusedNumber() {
        const list = I3.workspaces.values;
        for (let i = 0; i < list.length; i++) if (list[i].focused) return list[i].number;
        return -1;
    }
    function i3Has(n) {
        const list = I3.workspaces.values;
        for (let i = 0; i < list.length; i++) if (list[i].number === n) return true;
        return false;
    }
    function i3Urgent(n) {
        const list = I3.workspaces.values;
        for (let i = 0; i < list.length; i++) if (list[i].number === n && list[i].urgent) return true;
        return false;
    }
    function i3MaxNumber() {
        const list = I3.workspaces.values;
        let m = 0;
        for (let i = 0; i < list.length; i++) m = Math.max(m, list[i].number);
        return m;
    }

    // one long-lived subscription: window focus/title changes + workspace switches
    function i3Event(line) {
        let e;
        try { e = JSON.parse(line); } catch (err) { return; }
        if (e.container) {                                           // a window event
            if (e.change === "focus" || (e.change === "title" && e.container.focused))
                winTitle = e.container.name || "";
            else if (e.change === "close")
                winTitle = "";
            if (e.change === "focus" && anyPopup && !popupAge.running) closePending = true;
        } else if (e.current && e.change === "focus") {              // a workspace switch
            winTitle = "";                                           // the window::focus event that follows refills it
            if (anyPopup && !popupAge.running) closePending = true;
        }
    }
    Process {
        id: i3Events
        running: true
        command: ["i3-msg", "-t", "subscribe", "-m", "[\"window\",\"workspace\"]"]
        stdout: SplitParser { onRead: data => root.i3Event(data) }
        onExited: i3Retry.start()                                   // i3 restarted -> reconnect
    }
    Timer { id: i3Retry; interval: 2000; onTriggered: i3Events.running = true }

    // ───────────── system stats: ONE long-lived shell loop, no per-tick forks ─────────────
    readonly property string sysScript: [
        "while :; do",
        "  read -r _ u n s i w q sq st _ < /proc/stat",
        "  while read -r k v _; do",
        "    case $k in MemTotal:) t=$v;; MemAvailable:) a=$v;; esac",
        "  done < /proc/meminfo",
        "  c=0; l=0",
        "  while read -r k st2 link _; do",
        "    c=$((c+1))",
        "    if [ $c -gt 2 ]; then l=${link%.}; break; fi",
        "  done < /proc/net/wireless",
        "  echo $u $n $s $i $w $q $sq $st $t $a ${l:-0}",
        "  sleep 3",
        "done"
    ].join("\n")

    function parseSys(line) {
        const p = line.trim().split(" ").map(Number);
        if (p.length < 11) return;
        const idle = p[3] + p[4];
        const total = p[0] + p[1] + p[2] + p[3] + p[4] + p[5] + p[6] + p[7];
        if (prevTotal > 0) {
            const dt = total - prevTotal;
            const di = idle - prevIdle;
            cpuUsage = dt > 0 ? Math.round((1 - di / dt) * 100) : 0;
        }
        prevTotal = total;
        prevIdle = idle;
        memUsage = p[8] > 0 ? Math.round((1 - p[9] / p[8]) * 100) : 0;
        wifiQuality = Math.min(100, Math.round(p[10] * 100 / 70));
    }
    Process {
        id: sysProc
        running: true
        command: ["bash", "-c", root.sysScript]
        stdout: SplitParser { onRead: data => root.parseSys(data) }
    }

    // ───────────── bluetooth ─────────────
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btAvailable: btAdapter ? true : false
    readonly property bool btOn: btAdapter ? btAdapter.enabled : false

    function btConnectedCount() {
        if (!btAdapter) return 0;
        const list = btAdapter.devices.values;
        let n = 0;
        for (let i = 0; i < list.length; i++) if (list[i].connected) n++;
        return n;
    }
    function btPairedCount() {
        if (!btAdapter) return 0;
        const list = btAdapter.devices.values;
        let n = 0;
        for (let i = 0; i < list.length; i++) if (list[i].paired) n++;
        return n;
    }
    function btHeadline() {                    // battery % of the first connected device that reports one
        if (!btAdapter) return "";
        const list = btAdapter.devices.values;
        for (let i = 0; i < list.length; i++) {
            const d = list[i];
            if (d.connected && d.batteryAvailable) return Math.round(d.battery * 100) + "%";
        }
        return "";
    }
    function btStatus(d) {
        if (d.state === 3) return "Connecting…";
        if (d.state === 2) return "Disconnecting…";
        if (d.connected) return d.batteryAvailable ? "Connected · " + Math.round(d.battery * 100) + "%" : "Connected";
        return "Not connected";
    }

    // ───────────── now playing (Firefox) ─────────────
    function pickPlayer() {
        const list = Mpris.players.values;
        let best = null;
        let bestScore = -1;
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            const id = ((p.identity || "") + " " + (p.desktopEntry || "") + " " + (p.dbusName || "")).toLowerCase();
            if (id.indexOf("firefox") < 0) continue;
            let score = 0;
            if (p.playbackState === MprisPlaybackState.Playing) score += 10;
            if ((p.trackArtist || "") !== "") score += 2;
            if ((p.trackArtUrl || "") !== "") score += 2;
            if (score > bestScore) { best = p; bestScore = score; }
        }
        return best;
    }
    readonly property var player: pickPlayer()
    readonly property bool playing: player ? player.playbackState === MprisPlaybackState.Playing : false

    // Firefox only hands over the tab title for SoundCloud ("Track by Artist") and leaves the artist empty,
    // so split it ourselves when the artist is missing.
    readonly property string rawTitle: player ? (player.trackTitle || "") : ""
    readonly property string rawArtist: player ? (player.trackArtist || "") : ""
    readonly property int byIndex: rawTitle.lastIndexOf(" by ")
    readonly property string songTitle: (rawArtist === "" && byIndex > 0) ? rawTitle.substring(0, byIndex) : rawTitle
    readonly property string songArtist: rawArtist !== "" ? rawArtist : (byIndex > 0 ? rawTitle.substring(byIndex + 4) : "")

    // Firefox gives no cover for SoundCloud, so look the track up (yt-dlp) once, only while the popup is open.
    readonly property string trackKey: songArtist + "|" + songTitle
    property string lookedUpArt: ""
    property string lookedUpKey: ""
    property string pendingKey: ""
    readonly property string artUrl: (player && (player.trackArtUrl || "") !== "") ? player.trackArtUrl
                                     : (lookedUpKey === trackKey ? lookedUpArt : "")
    onTrackKeyChanged: artDebounce.restart()

    Process {
        id: artProc
        command: ["yt-dlp", "--no-warnings", "--playlist-items", "1", "--print", "thumbnail",
                  "scsearch1:" + root.songArtist + " " + root.songTitle]
        stdout: SplitParser {
            onRead: data => {
                const u = data.trim();
                if (u.indexOf("http") === 0) {
                    root.lookedUpArt = u;
                    root.lookedUpKey = root.pendingKey;
                }
            }
        }
    }
    Timer {
        id: artDebounce
        interval: 800
        onTriggered: {
            const native = root.player && (root.player.trackArtUrl || "") !== "";
            if (root.mediaOpen && root.player && root.songTitle !== "" && !native
                    && root.lookedUpKey !== root.trackKey && !artProc.running) {
                root.pendingKey = root.trackKey;
                artProc.running = true;
            }
        }
    }

    function fmtTime(sec) {
        const t = Math.max(0, Math.floor(sec || 0));
        const h = Math.floor(t / 3600);
        const m = Math.floor((t % 3600) / 60);
        const r = t % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? h + ":" + pad(m) + ":" + pad(r) : m + ":" + pad(r);
    }

    // ───────────── cava (Firefox's audio only, via firefox-cava.sh) ─────────────
    function parseCava(line) {                 // full feed (popup)
        const v = line.split(";").filter(x => x.length > 0).map(Number);
        let peak = 0;
        for (let i = 0; i < v.length; i++) peak = Math.max(peak, v[i]);
        if (peak <= 1) {
            cavaFlat++;
            if (cavaFlat > 25) { cavaActive = false; return; }     // ~1s of silence -> hide, stop redrawing
        } else {
            cavaFlat = 0;
            cavaActive = true;
        }
        cavaBars = v;
    }
    function parseMini(line) {                 // light feed (bar equalizer)
        const v = line.split(";").filter(x => x.length > 0).map(Number);
        if (v.length > 0) miniBars = v;
    }
    // 5 chunky levels (0..1) for the little equalizer, averaged from however many bars cava sends
    function miniLevel(i) {
        const b = miniBars;
        const n = b.length;
        if (n < 1) return 0;
        const start = Math.floor(i * n / 5);
        const end = Math.max(start + 1, Math.floor((i + 1) * n / 5));
        let sum = 0, cnt = 0;
        for (let k = start; k < end && k < n; k++) { sum += b[k]; cnt++; }
        return cnt > 0 ? sum / cnt / 100 : 0;
    }

    // full feed (popup bars) — see fullWanted above
    Process {
        id: cavaProc
        running: false
        command: ["bash", Quickshell.shellPath("firefox-cava.sh"), Quickshell.shellPath("cava.conf"), "popup"]
        stdout: SplitParser { onRead: data => root.parseCava(data) }
        onExited: if (root.fullWanted) cavaRetry.start()
    }
    Timer { id: cavaRetry; interval: 3000; onTriggered: if (root.fullWanted) cavaProc.running = true }

    // light feed (bar equalizer) — runs while a song plays
    Process {
        id: miniProc
        running: false
        command: ["bash", Quickshell.shellPath("firefox-cava.sh"), Quickshell.shellPath("cava-bar.conf"), "bar"]
        stdout: SplitParser { onRead: data => root.parseMini(data) }
        onExited: if (root.playing) miniRetry.start()
    }
    Timer { id: miniRetry; interval: 3000; onTriggered: if (root.playing) miniProc.running = true }

    // ═════════════════════════════ the bar ═════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            readonly property string screenName: modelData.name

            anchors { top: true; left: true; right: true }
            margins { top: root.s(6); left: root.s(10); right: root.s(10) }
            implicitHeight: root.barHeight
            color: "transparent"

            Item {
                anchors.fill: parent

                // ───────── left island: workspaces + window title ─────────
                Rectangle {
                    id: leftIsland
                    anchors.left: parent.left
                    height: parent.height
                    width: leftRow.implicitWidth + root.s(16)
                    radius: root.s(12)
                    color: Qt.alpha(root.bgBase, 0.9)
                    border.width: 1
                    border.color: Qt.alpha(root.slate, 0.7)

                    RowLayout {
                        id: leftRow
                        anchors.centerIn: parent
                        spacing: root.s(2)

                        Repeater {
                            model: Math.min(10, Math.max(root.workspaceCount, root.i3MaxNumber()))

                            delegate: Item {
                                id: ws
                                required property int index
                                readonly property int wsId: index + 1
                                readonly property bool active: root.i3FocusedNumber() === wsId
                                readonly property bool exists: root.i3Has(wsId)
                                readonly property bool urgent: root.i3Urgent(wsId)
                                implicitWidth: Math.max(root.s(26), wsLabel.implicitWidth + root.s(14))
                                implicitHeight: root.s(24)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: root.s(8)
                                    color: ws.active ? Qt.alpha(root.horizon, 0.16)
                                                     : (wsMouse.containsMouse ? Qt.alpha(root.slateHi, 0.3) : "transparent")
                                }
                                Text {
                                    id: wsLabel
                                    anchors.centerIn: parent
                                    text: ws.wsId
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize
                                    font.weight: ws.active ? Font.DemiBold : Font.Normal
                                    color: ws.urgent ? root.red
                                           : (ws.active ? root.fgPrimary : (ws.exists ? root.fgMuted : root.fgDim))
                                }
                                MouseArea {
                                    id: wsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: I3.dispatch("workspace number " + ws.wsId)
                                }
                            }
                        }

                        Text {
                            Layout.leftMargin: root.s(8)
                            Layout.maximumWidth: root.s(240)
                            text: root.winTitle
                            visible: text.length > 0
                            elide: Text.ElideRight
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize - 1
                            color: root.fgDim
                        }
                    }
                }

                // ───────── center island: the clock — or the song while something plays ─────────
                Rectangle {
                    id: centerIsland
                    anchors.centerIn: parent
                    height: parent.height
                    width: centerBox.width + root.s(28)
                    radius: root.s(12)
                    color: Qt.alpha(root.bgBase, 0.9)
                    border.width: 1
                    border.color: Qt.alpha(root.slate, 0.7)

                    Item {
                        id: centerBox
                        anchors.centerIn: parent
                        height: parent.height
                        width: showSong ? songRow.width : clockText.implicitWidth

                        readonly property bool showSong: root.playing
                        readonly property string songText: {
                            if (!root.player) return "";
                            const t = root.songTitle;
                            const a = root.songArtist;
                            return a.length > 0 ? a + " — " + t : t;
                        }
                        onSongTextChanged: {
                            scrollTimer.offset = 0;
                            scrollTimer.hold = 1800;
                            scroller.x = 0;
                        }

                        // the time (nothing playing)
                        Text {
                            id: clockText
                            anchors.centerIn: parent
                            visible: !centerBox.showSong
                            text: Qt.formatDateTime(clock.date, root.showDate ? "dddd, d MMMM" : "HH:mm")
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                            color: root.fgPrimary
                        }

                        // the song (playing)
                        Row {
                            id: songRow
                            anchors.centerIn: parent
                            spacing: root.s(10)
                            visible: centerBox.showSong

                            // little live equalizer: 5 bars from the real audio
                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 5 * root.s(3) + 4 * 2
                                height: root.s(14)

                                Row {
                                    spacing: 2
                                    height: parent.height

                                    Repeater {
                                        model: 5

                                        delegate: Item {
                                            id: mslot
                                            required property int index
                                            width: root.s(3)
                                            height: root.s(14)

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                radius: width / 2
                                                height: Math.max(3, Math.min(1, Math.pow(root.miniLevel(mslot.index), 0.6)) * root.s(14))
                                                color: root.horizon
                                            }
                                        }
                                    }
                                }
                            }

                            // title: sits still if it fits, marquee-scrolls if it doesn't
                            Item {
                                id: marquee
                                anchors.verticalCenter: parent.verticalCenter
                                readonly property real maxW: root.s(240)
                                readonly property real gap: root.s(48)
                                readonly property bool overflow: songLabel.implicitWidth > maxW
                                width: Math.min(maxW, songLabel.implicitWidth)
                                height: root.s(20)
                                clip: true

                                Item {
                                    id: scroller
                                    height: parent.height

                                    Text {
                                        id: songLabel
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: centerBox.songText
                                        font.family: root.fontFamily
                                        font.pixelSize: root.fontSize
                                        font.weight: Font.DemiBold
                                        color: root.fgPrimary
                                    }
                                    Text {                       // second copy so the loop wraps seamlessly
                                        visible: marquee.overflow
                                        x: songLabel.implicitWidth + marquee.gap
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: centerBox.songText
                                        font.family: root.fontFamily
                                        font.pixelSize: root.fontSize
                                        font.weight: Font.DemiBold
                                        color: root.fgPrimary
                                    }
                                }

                                // whole-pixel scroll at ~20px/s; only ticks when the title really overflows
                                Timer {
                                    id: scrollTimer
                                    interval: 50
                                    repeat: true
                                    running: marquee.overflow && centerBox.showSong
                                    property real offset: 0
                                    property int hold: 1800
                                    onRunningChanged: {
                                        offset = 0;
                                        hold = 1800;
                                        scroller.x = 0;
                                    }
                                    onTriggered: {
                                        if (hold > 0) { hold -= interval; return; }
                                        offset += 1;
                                        if (offset >= songLabel.implicitWidth + marquee.gap) {
                                            offset = 0;
                                            hold = 1800;
                                        }
                                        scroller.x = -offset;
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                root.showDate = !root.showDate;
                            else
                                root.openPopup("media", bar.screenName, centerIsland.mapToItem(null, centerIsland.width / 2, 0).x);
                        }
                    }
                }

                // ───────── right island: status ─────────
                Rectangle {
                    id: rightIsland
                    anchors.right: parent.right
                    height: parent.height
                    width: rightRow.implicitWidth + root.s(28)
                    radius: root.s(12)
                    color: Qt.alpha(root.bgBase, 0.9)
                    border.width: 1
                    border.color: Qt.alpha(root.slate, 0.7)

                    RowLayout {
                        id: rightRow
                        anchors.centerIn: parent
                        spacing: root.s(14)

                        // volume: click = mute, right-click = mixer, scroll = ±5%
                        Text {
                            text: root.volumeIcon() + "  " + (root.muted ? "muted" : Math.round(root.volume * 100) + "%")
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            color: volMouse.containsMouse ? root.horizon : root.fgMuted

                            MouseArea {
                                id: volMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) Quickshell.execDetached(["pavucontrol"]);
                                    else if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted;
                                }
                                onWheel: wheel => root.setVolume(root.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
                            }
                        }

                        // wifi
                        Text {
                            text: root.wifiQuality > 0 ? "\uf1eb  " + root.wifiQuality + "%" : "\uf00d  offline"
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            color: netMouse.containsMouse ? root.horizon : root.fgMuted

                            MouseArea {
                                id: netMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["nm-connection-editor"])
                            }
                        }

                        // bluetooth: click = device list, right-click = settings
                        Text {
                            id: btIcon
                            visible: root.btAvailable
                            text: "\uf294" + (root.btHeadline() !== "" ? "  " + root.btHeadline() : "")
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            color: btMouse.containsMouse ? root.horizon
                                   : (!root.btOn ? root.fgDim : (root.btConnectedCount() > 0 ? root.horizon : root.fgMuted))

                            MouseArea {
                                id: btMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton)
                                        Quickshell.execDetached(["blueman-manager"]);
                                    else
                                        root.openPopup("bt", bar.screenName, btIcon.mapToItem(null, btIcon.width / 2, 0).x);
                                }
                            }
                        }

                        Text {                                   // cpu
                            text: "\uf2db  " + root.cpuUsage + "%"
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            color: root.fgMuted
                        }

                        Text {                                   // memory
                            text: "\uf1c0  " + root.memUsage + "%"
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            color: root.fgMuted
                        }

                        Text {                                   // battery: amber at 30%, blinking red at 15%
                            visible: root.hasBattery
                            text: root.batteryIcon() + "  " + root.batPct + "%"
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            color: root.batCritical ? root.red : (root.batWarning ? root.amber : root.fgMuted)
                            opacity: (root.batCritical && root.blinkOff) ? 0.35 : 1.0
                        }

                        // system tray
                        Row {
                            visible: trayRepeater.count > 0
                            spacing: root.s(8)
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                id: trayRepeater
                                model: SystemTray.items

                                delegate: Item {
                                    id: trayItem
                                    required property var modelData
                                    width: root.s(16)
                                    height: root.s(16)

                                    // keep this app's menu "open" in the background: apps that drop their menu when it is
                                    // closed (Chromium/Electron/Steam) would otherwise come back empty next time
                                    QsMenuOpener { menu: trayItem.modelData.menu }

                                    IconImage {
                                        anchors.fill: parent
                                        source: trayItem.modelData.icon
                                        opacity: trayMouse.containsMouse ? 1.0 : 0.8
                                    }

                                    MouseArea {
                                        id: trayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        onClicked: mouse => {
                                            const it = trayItem.modelData;
                                            const x = trayItem.mapToItem(null, trayItem.width / 2, 0).x;
                                            if (mouse.button === Qt.LeftButton) {
                                                if (it.onlyMenu && it.hasMenu) root.openTrayMenu(it, bar.screenName, x);
                                                else it.activate();
                                            } else if (mouse.button === Qt.MiddleButton) {
                                                it.secondaryActivate();
                                            } else if (it.hasMenu) {
                                                root.openTrayMenu(it, bar.screenName, x);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // power
                        Text {
                            text: "\uf011"
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize + 1
                            color: powerMouse.containsMouse ? root.red : root.fgMuted

                            MouseArea {
                                id: powerMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["bash", "-c", root.i3PowerCmd])
                            }
                        }
                    }
                }
            }

            // ═════════════════ popups ═════════════════

            // ───────────── now-playing popup (click the clock) ─────────────
            LazyLoader {
                active: root.mediaOpen && root.popupScreen === bar.screenName

                PopupWindow {
                    id: media
                    anchor.window: bar
                    anchor.rect.x: Math.max(4, Math.min(bar.width - width - 4, root.popupX - width / 2))
                    anchor.rect.y: bar.height + root.s(6)
                    implicitWidth: 440
                    implicitHeight: 188
                    visible: root.mediaOpen
                    color: "transparent"

                    // keep the elapsed time ticking — only while open AND playing
                    Timer {
                        interval: 1000
                        repeat: true
                        running: root.playing
                        onTriggered: if (root.player) root.player.positionChanged()
                    }

                    Rectangle {
                        id: panel
                        anchors.fill: parent
                        radius: 16
                        color: Qt.alpha(root.bgBase, 0.95)
                        border.width: 1
                        border.color: Qt.alpha(root.slate, 0.8)
                        HoverHandler { onHoveredChanged: root.popupHovered = hovered }

                        // ── visualizer: rises from the bottom, BEHIND everything ──
                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: panel.radius - 1
                            color: "transparent"
                            opacity: (root.cavaActive && root.playing) ? 1 : 0

                            Row {
                                id: vizRow
                                height: parent.height
                                spacing: 5

                                readonly property int count: Math.max(1, root.cavaBars.length)
                                readonly property real barW: (parent.width - spacing * (count - 1)) / count

                                Repeater {
                                    model: root.cavaBars.length

                                    delegate: Item {
                                        id: slot
                                        required property int index
                                        readonly property real level: root.playing ? (root.cavaBars[index] || 0) / 100 : 0
                                        width: vizRow.barW
                                        height: vizRow.height

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: Math.max(3, slot.level * slot.height * 0.8)
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: Qt.alpha(root.horizon, 0.07 + 0.20 * slot.level) }
                                                GradientStop { position: 1.0; color: Qt.alpha(root.horizon, 0.02) }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── cover: real artwork if there is any, otherwise a music-note tile ──
                        ClippingRectangle {
                            id: art
                            visible: root.player ? true : false
                            x: 18; y: 18
                            width: 80; height: 80
                            radius: 12
                            color: root.slate

                            Text {
                                anchors.centerIn: parent
                                visible: artImage.status !== Image.Ready
                                text: "\uf001"
                                font.family: root.fontFamily
                                font.pixelSize: 30
                                color: root.fgDim
                            }
                            Image {
                                id: artImage
                                anchors.fill: parent
                                source: root.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 160
                                sourceSize.height: 160
                            }
                        }

                        // ── time + date in the corner ──
                        Column {
                            id: corner
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 16
                            anchors.rightMargin: 20
                            spacing: 2

                            Text {
                                anchors.right: parent.right
                                text: Qt.formatDateTime(clock.date, "HH:mm")
                                font.family: root.fontFamily
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                color: root.fgPrimary
                            }
                            Text {
                                anchors.right: parent.right
                                text: Qt.formatDateTime(clock.date, "ddd, d MMM")
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: root.fgDim
                            }
                        }

                        // ── the song, front and center ──
                        Column {
                            anchors.left: art.visible ? art.right : parent.left
                            anchors.leftMargin: art.visible ? 16 : 20
                            anchors.right: corner.left
                            anchors.rightMargin: 14
                            anchors.top: parent.top
                            anchors.topMargin: 22
                            spacing: 6

                            Text {
                                width: parent.width
                                text: root.player ? (root.songTitle || "Unknown title") : "Nothing playing"
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                color: root.player ? root.fgPrimary : root.fgDim
                            }
                            Text {
                                width: parent.width
                                text: root.player ? root.songArtist : "Play something in Firefox"
                                visible: text.length > 0
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                color: root.fgMuted
                            }
                        }

                        // ── elapsed / progress / total ──
                        Item {
                            id: progressRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            y: 112
                            height: 14

                            Text {
                                id: elapsedText
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.fmtTime(root.player ? root.player.position : 0)
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                color: root.fgMuted
                            }
                            Text {
                                id: totalText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.player && root.player.length > 0) ? root.fmtTime(root.player.length) : "--:--"
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                color: root.fgMuted
                            }

                            Rectangle {
                                anchors.left: elapsedText.right
                                anchors.right: totalText.left
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                height: 3
                                radius: 1.5
                                color: Qt.alpha(root.slateHi, 0.5)

                                Rectangle {
                                    height: parent.height
                                    radius: parent.radius
                                    color: root.horizon
                                    width: (root.player && root.player.length > 0)
                                           ? parent.width * Math.min(1, root.player.position / root.player.length)
                                           : 0
                                }
                            }
                        }

                        // ── controls ──
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 138
                            spacing: 26

                            Text {
                                id: prevBtn
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\uf048"
                                font.family: root.fontFamily
                                font.pixelSize: 15
                                readonly property bool usable: root.player ? root.player.canGoPrevious : false
                                color: prevMouse.containsMouse && usable ? root.fgPrimary : root.fgMuted
                                opacity: usable ? 1 : 0.35
                                MouseArea {
                                    id: prevMouse
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    enabled: prevBtn.usable
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.player.previous()
                                }
                            }

                            Rectangle {
                                width: 36; height: 36
                                radius: 18
                                color: Qt.alpha(root.horizon, playMouse.containsMouse ? 0.22 : 0.14)
                                border.width: 1
                                border.color: Qt.alpha(root.horizon, 0.35)
                                opacity: playMouse.enabled ? 1 : 0.35

                                Text {
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: root.playing ? 0 : 1     // optical centering for the triangle
                                    text: root.playing ? "\uf04c" : "\uf04b"
                                    font.family: root.fontFamily
                                    font.pixelSize: 15
                                    color: root.horizon
                                }
                                MouseArea {
                                    id: playMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: root.player ? root.player.canTogglePlaying : false
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.player.togglePlaying()
                                }
                            }

                            Text {
                                id: nextBtn
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\uf051"
                                font.family: root.fontFamily
                                font.pixelSize: 15
                                readonly property bool usable: root.player ? root.player.canGoNext : false
                                color: nextMouse.containsMouse && usable ? root.fgPrimary : root.fgMuted
                                opacity: usable ? 1 : 0.35
                                MouseArea {
                                    id: nextMouse
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    enabled: nextBtn.usable
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.player.next()
                                }
                            }
                        }
                    }
                }
            }

            // ───────────── tray context menu (themed) ─────────────
            LazyLoader {
                active: root.trayMenuOpen && root.popupScreen === bar.screenName

                PopupWindow {
                    id: trayMenu
                    anchor.window: bar
                    anchor.rect.x: Math.max(4, Math.min(bar.width - width - 4, root.popupX - width / 2))
                    anchor.rect.y: bar.height + root.s(6)
                    implicitWidth: 240
                    implicitHeight: menuCard.height
                    visible: root.trayMenuOpen
                    color: "transparent"

                    QsMenuOpener { id: menuOpener; menu: root.trayMenuHandle }

                    // nothing to show after half a second -> give up instead of holding an empty window
                    Timer {
                        interval: 500
                        running: true
                        onTriggered: if (menuOpener.children.values.length === 0 && root.trayMenuStack.length === 0) root.trayMenuOpen = false
                    }

                    Rectangle {
                        id: menuCard
                        width: 240
                        height: menuCol.implicitHeight + 16
                        radius: 12
                        color: Qt.alpha(root.bgBase, 0.96)
                        border.width: 1
                        border.color: Qt.alpha(root.slate, 0.8)
                        HoverHandler { onHoveredChanged: root.popupHovered = hovered }
                        visible: menuOpener.children.values.length > 0

                        Column {
                            id: menuCol
                            x: 8; y: 8
                            width: parent.width - 16
                            spacing: 2

                            // "Back" row, only inside a submenu
                            Item {
                                visible: root.trayMenuStack.length > 0
                                width: menuCol.width
                                height: 28

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: backMouse.containsMouse ? Qt.alpha(root.slateHi, 0.35) : "transparent"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 8
                                    text: "\uf053   Back"
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    color: root.fgMuted
                                }
                                MouseArea {
                                    id: backMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        const st = root.trayMenuStack.slice();
                                        root.trayMenuHandle = st.pop();
                                        root.trayMenuStack = st;
                                    }
                                }
                            }

                            Repeater {
                                model: menuOpener.children

                                delegate: Item {
                                    id: entry
                                    required property var modelData
                                    width: menuCol.width
                                    height: entry.modelData.isSeparator ? 9 : 28

                                    Rectangle {                 // separator
                                        visible: entry.modelData.isSeparator
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        height: 1
                                        color: Qt.alpha(root.slateHi, 0.5)
                                    }

                                    Rectangle {                 // hover highlight
                                        visible: !entry.modelData.isSeparator
                                        anchors.fill: parent
                                        radius: 6
                                        color: (entryMouse.containsMouse && entry.modelData.enabled) ? Qt.alpha(root.slateHi, 0.35) : "transparent"
                                    }

                                    RowLayout {
                                        visible: !entry.modelData.isSeparator
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8
                                        opacity: entry.modelData.enabled ? 1 : 0.4

                                        Text {                  // checkbox / radio tick
                                            Layout.preferredWidth: 12
                                            text: (entry.modelData.buttonType !== QsMenuButtonType.None && entry.modelData.checkState === Qt.Checked) ? "\uf00c" : ""
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            color: root.horizon
                                        }
                                        Image {
                                            visible: entry.modelData.icon !== ""
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            source: entry.modelData.icon
                                            sourceSize.width: 32
                                            sourceSize.height: 32
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: entry.modelData.text
                                            elide: Text.ElideRight
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            color: root.fgPrimary
                                        }
                                        Text {
                                            visible: entry.modelData.hasChildren
                                            text: "\uf054"
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            color: root.fgDim
                                        }
                                    }

                                    MouseArea {
                                        id: entryMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: !entry.modelData.isSeparator
                                        onClicked: {
                                            if (!entry.modelData.enabled) return;
                                            if (entry.modelData.hasChildren) {
                                                root.trayMenuStack = root.trayMenuStack.concat([root.trayMenuHandle]);
                                                root.trayMenuHandle = entry.modelData;
                                            } else {
                                                entry.modelData.triggered();
                                                root.closeAllPopups();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ───────────── bluetooth popup (device list) ─────────────
            LazyLoader {
                active: root.btOpen && root.popupScreen === bar.screenName

                PopupWindow {
                    id: btPopup
                    anchor.window: bar
                    anchor.rect.x: Math.max(4, Math.min(bar.width - width - 4, root.popupX - width / 2))
                    anchor.rect.y: bar.height + root.s(6)
                    implicitWidth: 260
                    implicitHeight: btCard.height
                    visible: root.btOpen
                    color: "transparent"

                    Rectangle {
                        id: btCard
                        width: 260
                        height: btCol.implicitHeight + 20
                        radius: 12
                        color: Qt.alpha(root.bgBase, 0.96)
                        border.width: 1
                        border.color: Qt.alpha(root.slate, 0.8)
                        HoverHandler { onHoveredChanged: root.popupHovered = hovered }

                        Column {
                            id: btCol
                            x: 10; y: 10
                            width: parent.width - 20
                            spacing: 4

                            // header: title + power switch
                            Item {
                                width: btCol.width
                                height: 30

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\uf294   Bluetooth"
                                    font.family: root.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: root.fgPrimary
                                }

                                Rectangle {
                                    id: btSwitch
                                    anchors.right: parent.right
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38; height: 20
                                    radius: 10
                                    color: root.btOn ? Qt.alpha(root.horizon, 0.35) : Qt.alpha(root.slateHi, 0.5)

                                    Rectangle {
                                        y: 3
                                        width: 14; height: 14
                                        radius: 7
                                        x: root.btOn ? btSwitch.width - width - 3 : 3
                                        color: root.btOn ? root.horizon : root.fgDim
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.btAdapter) root.btAdapter.enabled = !root.btAdapter.enabled
                                    }
                                }
                            }

                            Rectangle { width: btCol.width; height: 1; color: Qt.alpha(root.slateHi, 0.5) }

                            Text {
                                visible: !root.btOn
                                x: 6
                                text: "Bluetooth is turned off"
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                color: root.fgDim
                                height: visible ? 28 : 0
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                visible: root.btOn && root.btPairedCount() === 0
                                x: 6
                                text: "No paired devices"
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                color: root.fgDim
                                height: visible ? 28 : 0
                                verticalAlignment: Text.AlignVCenter
                            }

                            // paired devices: click = connect / disconnect
                            Repeater {
                                model: root.btAdapter ? root.btAdapter.devices : null

                                delegate: Item {
                                    id: dev
                                    required property var modelData
                                    readonly property bool shown: root.btOn && modelData.paired
                                    readonly property bool linked: modelData.connected
                                    width: btCol.width
                                    height: shown ? 46 : 0
                                    visible: shown

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: devMouse.containsMouse ? Qt.alpha(root.slateHi, 0.3) : "transparent"
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Image {
                                            Layout.preferredWidth: 22
                                            Layout.preferredHeight: 22
                                            source: Quickshell.iconPath(dev.modelData.icon || "bluetooth")
                                            sourceSize.width: 44
                                            sourceSize.height: 44
                                            opacity: dev.linked ? 1 : 0.55
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                Layout.fillWidth: true
                                                text: dev.modelData.name || dev.modelData.deviceName || dev.modelData.address
                                                elide: Text.ElideRight
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                color: dev.linked ? root.fgPrimary : root.fgMuted
                                            }
                                            Text {
                                                text: root.btStatus(dev.modelData)
                                                font.family: root.fontFamily
                                                font.pixelSize: 10
                                                color: dev.linked ? root.horizon : root.fgDim
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: devMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: dev.modelData.connected = !dev.modelData.connected
                                    }
                                }
                            }

                            Rectangle { width: btCol.width; height: 1; color: Qt.alpha(root.slateHi, 0.5) }

                            // footer: bluetooth settings (pairing new devices lives there)
                            Item {
                                width: btCol.width
                                height: 30

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: settingsMouse.containsMouse ? Qt.alpha(root.slateHi, 0.3) : "transparent"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 8
                                    text: "Bluetooth settings…"
                                    font.family: root.fontFamily
                                    font.pixelSize: 11
                                    color: root.fgMuted
                                }
                                MouseArea {
                                    id: settingsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["blueman-manager"]);
                                        root.closeAllPopups();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Quickshell — "Slate Tide" bar
// Palette from a hazy dusk seascape: ink-dark base, slate-indigo greys, and one
// pale "horizon" glow used only for the active workspace and hover states.
// Needs a Nerd Font (JetBrainsMono Nerd Font) and `cava` for the visualizer.
// Icons are \uXXXX escapes (Font Awesome 4 codepoints) so they survive copy/paste.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Bluetooth
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
    readonly property real uiScale: 1.25       // <- the one knob: 1.0 = old size, 1.25 = bigger, 1.5 = much bigger
    readonly property int fontSize: Math.round(12 * uiScale)
    readonly property int workspaceCount: 5

    // ───────────── which desktop are we running on? ─────────────
    // Hyprland -> native workspaces/title/focus-grab. Anything else (KDE Plasma) -> D-Bus + xdg-popup grabs.
    readonly property bool isHypr: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
    readonly property bool isKde: (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toUpperCase().indexOf("KDE") >= 0
    // ───────────── bar visibility ─────────────
    //   "always"   = pinned, reserves its space (old behaviour)
    //   "autohide" = slides away whenever the pointer isn't on it; touch the top edge to bring it back
    //   "dodge"    = hides only while a window reaches the bar (Hyprland: via its IPC, Plasma: via a small KWin script)
    readonly property string barMode: "dodge"
    readonly property bool hidesAtAll: barMode !== "always"
    readonly property int showDelay: 100     // ms the pointer must rest on the edge before the bar opens
    readonly property int hideDelay: 450     // ms to wait before the bar hides again
    readonly property int slideMs: 130       // ms the slide takes (was 180)
    readonly property int barExtra: 4                                   // extra px of bar thickness (bigger click/hover target)
    readonly property int barHeight: Math.round(30 * uiScale) + barExtra
    readonly property int barStrip: Math.round(6 * uiScale) + barHeight  // px from the top that the bar occupies

    property bool windowUnderBar: false     // Hyprland: a window on this workspace overlaps the bar area
    property bool barHovered: false
    property bool edgeHovered: false
    property bool trayOpenAny: false
    property bool btOpenAny: false
    property bool barShown: true

    readonly property bool canDodge: isHypr || isKde
    readonly property bool wantHidden: hidesAtAll && (barMode === "autohide" || !canDodge || windowUnderBar)
    readonly property bool popupOpenAny: mediaOpen || trayOpenAny || btOpenAny
    readonly property bool keepOpen: !wantHidden || popupOpenAny || barHovered || edgeHovered
    // (handler only starts/stops timers; changing barShown right here fed back into keepOpen = binding loop)
    onKeepOpenChanged: {
        if (keepOpen) { hideTimer.stop(); showTimer.restart(); }
        else { showTimer.stop(); hideTimer.restart(); }
    }
    Timer { id: showTimer; interval: root.showDelay; onTriggered: if (root.keepOpen) root.barShown = true }
    Timer { id: hideTimer; interval: root.hideDelay; onTriggered: if (!root.keepOpen) root.barShown = false }

    // Hyprland only: does any window on the current workspace reach into the bar's strip?
    function refreshOverlap() {
        if (!isHypr) return;
        const bottom = barStrip;
        const wsId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        const list = Hyprland.toplevels.values;
        let hit = false;
        for (let i = 0; i < list.length; i++) {
            const o = list[i].lastIpcObject;
            if (!o || o.hidden === true || o.mapped === false) continue;
            if (!o.workspace || o.workspace.id !== wsId) continue;
            if (o.at && o.at[1] < bottom) { hit = true; break; }
        }
        windowUnderBar = hit;
    }
    Timer { id: overlapTimer; interval: 120; onTriggered: root.refreshOverlap() }
    Connections {
        target: root.isHypr ? Hyprland : null
        function onRawEvent(event) {
            const n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2"
                    || n === "fullscreen" || n === "workspace" || n === "workspacev2" || n === "activewindow"
                    || n === "activewindowv2" || n === "changefloatingmode" || n === "focusedmon") {
                Hyprland.refreshToplevels();
                overlapTimer.restart();
            }
        }
    }

    property int kdeDesktop: 1          // current virtual desktop (1-based), from KWin
    property int kdeDesktopCount: 0

    // run a KDE settings tool on Plasma (falling back to the generic one), the generic one elsewhere
    function launch(kdeCmd, otherCmd) {
        const cmd = (isKde && !isHypr) ? (kdeCmd + " || " + otherCmd) : otherCmd;
        Quickshell.execDetached(["bash", "-c", cmd]);
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
    // battery % of the first connected device that reports one ("" if none)
    function btHeadline() {
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

    // ───────────── KDE Plasma: virtual desktops from KWin over D-Bus (event driven) ─────────────
    readonly property string kdeQueryScript: [
        "Q=$(command -v qdbus6 || command -v qdbus)",
        "[ -z \"$Q\" ] && exit 0",
        "cur=$($Q org.kde.KWin /KWin org.kde.KWin.currentDesktop)",
        "cnt=$($Q org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count)",
        "echo \"$cur ${cnt:-0}\""
    ].join("\n")

    function parseKde(line) {
        const p = line.trim().split(" ").map(Number);
        if (p.length < 1 || isNaN(p[0])) return;
        kdeDesktop = p[0] > 0 ? p[0] : 1;
        kdeDesktopCount = (p.length > 1 && p[1] > 0) ? p[1] : Math.max(kdeDesktop, 1);
    }

    Process {
        id: kdeQuery
        command: ["bash", "-c", root.kdeQueryScript]
        stdout: SplitParser { onRead: data => root.parseKde(data) }
    }
    Process {
        id: kdeMonitor
        running: root.isKde && !root.isHypr
        command: ["dbus-monitor", "--session",
                  "type='signal',interface='org.kde.KWin.VirtualDesktopManager',member='currentChanged'",
                  "type='signal',interface='org.kde.KWin.VirtualDesktopManager',member='desktopsChanged'"]
        stdout: SplitParser { onRead: data => { if (data.indexOf("member=") >= 0) kdeDebounce.restart(); } }
    }
    Timer { id: kdeDebounce; interval: 80; onTriggered: kdeQuery.running = true }

    // ───────────── KDE Plasma: window-dodging. A tiny KWin script reports "a window reaches the bar" ─────────────
    readonly property string dodgeLoadScript: [
        "Q=$(command -v qdbus6 || command -v qdbus)",
        "[ -z \"$Q\" ] && exit 0",
        "out=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell-dodge.js\"",
        "sed \"s/__STRIP__/$2/\" \"$1\" > \"$out\"",
        "$Q org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript quickshell-dodge >/dev/null 2>&1",
        "$Q org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript \"$out\" quickshell-dodge >/dev/null",
        "$Q org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null"
    ].join("\n")

    Process {
        id: dodgeLoader
        command: ["bash", "-c", root.dodgeLoadScript, "_", Quickshell.shellPath("dodge.js"), String(root.barStrip)]
    }
    Process {
        id: dodgeMonitor
        running: root.isKde && !root.isHypr && root.hidesAtAll && root.barMode !== "autohide"
        command: ["dbus-monitor", "--session",
                  "type='method_call',destination='org.freedesktop.DBus',member='NameHasOwner',arg0='quickshell.dodge.true'",
                  "type='method_call',destination='org.freedesktop.DBus',member='NameHasOwner',arg0='quickshell.dodge.false'"]
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("quickshell.dodge.true") >= 0) root.windowUnderBar = true;
                else if (data.indexOf("quickshell.dodge.false") >= 0) root.windowUnderBar = false;
            }
        }
    }

    // ───────────── live data ─────────────
    property real cpuUsage: 0
    property real memUsage: 0
    property real wifiQuality: 0
    property real prevTotal: 0
    property real prevIdle: 0

    property var cavaBars: []
    property bool cavaActive: false
    property int cavaFlat: 0
    property bool blinkOff: false
    property bool showDate: false
    property bool mediaOpen: false      // now-playing popup open?
    property var miniBars: []           // feed for the little equalizer in the bar

    // Two independent cava processes, so opening/closing the popup never disturbs the bar equalizer:
    //   - bar equalizer: light cava (cava-bar.conf), runs while a song is playing
    //   - popup visualizer: full cava (cava.conf), runs only while the popup is open
    onMediaOpenChanged: {
        artDebounce.restart();
        cavaFlat = 0;
        cavaProc.running = mediaOpen;
        if (!mediaOpen) { cavaActive = false; cavaBars = []; }
    }
    onPlayingChanged: {
        miniProc.running = playing;
        if (!playing) miniBars = [];
    }
    Component.onCompleted: {
        if (playing) miniProc.running = true;
        if (isKde && !isHypr) kdeQuery.running = true;
        if (isKde && !isHypr && hidesAtAll && barMode !== "autohide") dodgeLoader.running = true;
        if (isHypr) { Hyprland.refreshToplevels(); overlapTimer.restart(); }
        if (!keepOpen) hideTimer.restart();
    }

    // audio output (volume/mute)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    // battery
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat ? bat.isLaptopBattery : false
    readonly property int batPct: bat ? Math.round(bat.percentage * 100) : 0
    readonly property bool batCharging: bat ? bat.state === UPowerDeviceState.Charging : false
    readonly property bool batCritical: hasBattery && !batCharging && batPct <= 15
    readonly property bool batWarning: hasBattery && !batCharging && batPct <= 30

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ───────────── helpers ─────────────
    function workspaceExists(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id) return true;
        return false;
    }

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

    // 5 chunky levels (0..1) for the mini visualizer, averaged from however many bars cava sends
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

    function setVolume(v) {
        if (sink && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    // ───────────── media: follow Firefox's MPRIS player only ─────────────
    function pickPlayer() {
        // On Plasma there can be TWO browser players: Firefox's own and the Plasma Browser Integration one.
        // Plasma's media widget shows artist + cover, so PBI's player is usually the richer one.
        // Consider both; prefer playing, then whichever actually has an artist / cover art.
        const list = Mpris.players.values;
        let best = null;
        let bestScore = -1;
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            const id = ((p.identity || "") + " " + (p.desktopEntry || "") + " " + (p.dbusName || "")).toLowerCase();
            if (id.search(/firefox|browser.?integration/) < 0) continue;     // "Plasma Browser Integration" in any spelling
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

    // Firefox gives no cover art for SoundCloud, so look the track up (yt-dlp) while the popup is open.
    readonly property string trackKey: songArtist + "|" + songTitle
    property string lookedUpArt: ""
    property string lookedUpKey: ""
    property string pendingKey: ""
    readonly property string artUrl: (player && (player.trackArtUrl || "") !== "") ? player.trackArtUrl
                                     : (lookedUpKey === trackKey ? lookedUpArt : "")
    onTrackKeyChanged: artDebounce.restart()

    function fmtTime(sec) {
        const s = Math.max(0, Math.floor(sec || 0));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const r = s % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? h + ":" + pad(m) + ":" + pad(r) : m + ":" + pad(r);
    }

    // ───────────── system stats: ONE long-lived shell loop, no per-tick forks ─────────────
    // prints: cpu(8 jiffy fields) memTotal memAvailable wifiLinkQuality
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

    // ───────────── cava visualizer ─────────────
    function parseCava(line) {
        const v = line.split(";").filter(s => s.length > 0).map(Number);
        let peak = 0;
        for (let i = 0; i < v.length; i++) peak = Math.max(peak, v[i]);
        if (peak <= 1) {
            cavaFlat++;
            if (cavaFlat > 25) {           // ~1s of silence at 25fps -> hide, stop redrawing
                cavaActive = false;
                return;
            }
        } else {
            cavaFlat = 0;
            cavaActive = true;
        }
        cavaBars = v;
    }

    function parseMini(line) {
        const v = line.split(";").filter(x => x.length > 0).map(Number);
        if (v.length > 0) miniBars = v;
    }

    // cover lookup: one yt-dlp search per track, only while the popup is open
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

    // popup visualizer: full-resolution cava, only while the popup is open
    Process {
        id: cavaProc
        running: false
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        stdout: SplitParser { onRead: data => root.parseCava(data) }
        // at login PipeWire may not be ready yet — just retry
        onExited: if (root.mediaOpen) cavaRetry.start()
    }
    Timer { id: cavaRetry; interval: 3000; onTriggered: if (root.mediaOpen) cavaProc.running = true }

    // bar equalizer: light cava, only while a song is playing
    Process {
        id: miniProc
        running: false
        command: ["cava", "-p", Quickshell.shellPath("cava-bar.conf")]
        stdout: SplitParser { onRead: data => root.parseMini(data) }
        onExited: if (root.playing) miniRetry.start()
    }
    Timer { id: miniRetry; interval: 3000; onTriggered: if (root.playing) miniProc.running = true }

    // blinking "warning light" for critical battery (only ticks while critical)
    Timer {
        interval: 700
        repeat: true
        running: root.batCritical
        onTriggered: root.blinkOff = !root.blinkOff
        onRunningChanged: if (!running) root.blinkOff = false
    }

    // ───────────── the bar ─────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            // tray context menu state (our own themed menu — see bottom of this window)
            property var trayMenuHandle: null
            property var trayMenuStack: []
            property real trayMenuX: 0
            property bool trayMenuOpen: false
            property bool btOpen: false          // bluetooth popup
            property real btX: 0

            function openTrayMenu(item, x) {
                root.mediaOpen = false;
                btOpen = false;
                trayMenuStack = [];
                trayMenuHandle = item.menu;
                trayMenuX = x;
                trayMenuOpen = true;
            }

            anchors { top: true; left: true; right: true }
            margins { top: Math.round(6 * root.uiScale); left: Math.round(12 * root.uiScale); right: Math.round(12 * root.uiScale) }
            implicitHeight: root.barHeight
            color: "transparent"
            exclusionMode: root.hidesAtAll ? ExclusionMode.Ignore : ExclusionMode.Auto   // floating bars don't push windows
            visible: root.barShown || !barRect.fullyHidden                                // unmapped once it has slid away

            onTrayMenuOpenChanged: root.trayOpenAny = trayMenuOpen
            onBtOpenChanged: root.btOpenAny = btOpen

            Rectangle {
                id: barRect
                width: parent.width
                height: parent.height
                y: root.barShown ? 0 : -(height + Math.round(14 * root.uiScale))
                readonly property bool fullyHidden: y <= -height
                Behavior on y { NumberAnimation { duration: root.slideMs; easing.type: Easing.OutCubic } }

                radius: 12
                color: Qt.alpha(root.bgBase, 0.88)
                border.width: 1
                border.color: Qt.alpha(root.slate, 0.7)

                // passive pointer tracking: keeps the bar open while you're on it
                HoverHandler { onHoveredChanged: root.barHovered = hovered }

                // ───── left: workspaces + window title ─────
                RowLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: root.isHypr ? root.workspaceCount : Math.max(1, root.kdeDesktopCount)

                        delegate: Item {
                            id: ws
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool active: root.isHypr ? (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === wsId : false)
                                                                       : root.kdeDesktop === wsId
                            readonly property bool exists: root.isHypr ? root.workspaceExists(wsId) : true

                            implicitWidth: wsLabel.implicitWidth + Math.round(16 * root.uiScale)
                            implicitHeight: Math.round(22 * root.uiScale)

                            Text {
                                id: wsLabel
                                anchors.centerIn: parent
                                text: ws.wsId
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize
                                color: ws.active ? root.fgPrimary : (ws.exists ? root.fgMuted : root.fgDim)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // soft glow under the horizon line
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: -2
                                height: 6
                                radius: 3
                                width: ws.active ? parent.width - 6 : 0
                                color: Qt.alpha(root.horizon, 0.16)
                                Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                            }

                            // the horizon line itself
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                height: 2
                                radius: 1
                                width: ws.active ? parent.width - 10 : 0
                                color: root.horizon
                                Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.isHypr)   // Hyprland 0.55+ Lua dispatcher syntax
                                        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + ws.wsId + " })"]);
                                    else               // KDE Plasma: ask KWin to switch virtual desktop
                                        Quickshell.execDetached(["bash", "-c",
                                            "$(command -v qdbus6 || command -v qdbus) org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop " + ws.wsId]);
                                }
                            }
                        }
                    }

                    Text {
                        Layout.leftMargin: 8
                        Layout.maximumWidth: 260
                        text: (root.isHypr && Hyprland.activeToplevel) ? Hyprland.activeToplevel.title : ""
                        visible: text.length > 0
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize - 1
                        color: root.fgDim
                    }
                }

                // ───── center: the clock — or, while a song plays, the song ─────
                // (title scrolls if too long + a little live equalizer; click = popup, right-click = date)
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

                    // the time (when nothing is playing)
                    Text {
                        id: clockText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, root.showDate ? "dddd, d MMMM" : "HH:mm")
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        color: root.fgPrimary
                        opacity: centerBox.showSong ? 0 : 1
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // the song (when something is playing)
                    Row {
                        id: songRow
                        anchors.centerIn: parent
                        spacing: 10
                        opacity: centerBox.showSong ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        // little live equalizer: 5 bars from the real audio
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 5 * Math.round(3 * root.uiScale) + 4 * 2
                            height: Math.round(14 * root.uiScale)

                            Row {
                                spacing: 2
                                height: parent.height

                                Repeater {
                                    model: 5

                                    delegate: Item {
                                        id: mslot
                                        required property int index
                                        width: Math.round(3 * root.uiScale)
                                        height: Math.round(14 * root.uiScale)

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            radius: width / 2
                                            height: Math.max(3, Math.min(1, Math.pow(root.miniLevel(mslot.index), 0.6)) * Math.round(14 * root.uiScale))
                                            color: root.horizon
                                        }
                                    }
                                }
                            }
                        }

                        // scrolling title: sits still if it fits, marquee-scrolls if it doesn't
                        Item {
                            id: marquee
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property real maxW: Math.round(240 * root.uiScale)
                            readonly property real gap: 48
                            readonly property bool overflow: songLabel.implicitWidth > maxW
                            width: Math.min(maxW, songLabel.implicitWidth)
                            height: Math.round(20 * root.uiScale)
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
                                // second copy so the loop wraps around seamlessly
                                Text {
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

                            // manual ~20px/s scroll in whole pixels (crisp text), only ticks when it must
                            Timer {
                                id: scrollTimer
                                interval: 50
                                repeat: true
                                running: marquee.overflow && centerBox.showSong
                                property real offset: 0
                                property int hold: 1800        // pause before each pass, ms
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

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) root.showDate = !root.showDate;
                            else {
                                bar.btOpen = false;
                                bar.trayMenuOpen = false;
                                root.mediaOpen = !root.mediaOpen;
                            }
                        }
                    }
                }

                // ───── right: status ─────
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.round(16 * root.uiScale)

                    // volume: click = mute, right-click = mixer, scroll = ±5%
                    Text {
                        id: volText
                        text: root.volumeIcon() + "  " + (root.muted ? "muted" : Math.round(root.volume * 100) + "%")
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        color: volMouse.containsMouse ? root.horizon : root.fgMuted
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: volMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    root.launch("kcmshell6 kcm_pulseaudio", "pavucontrol");
                                else if (root.sink && root.sink.audio)
                                    root.sink.audio.muted = !root.sink.audio.muted;
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
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launch("kcmshell6 kcm_networkmanagement", "nm-connection-editor")
                        }
                    }

                    // bluetooth (KDE-style: icon in the bar, click = device list, right-click = settings)
                    Text {
                        id: btIcon
                        visible: root.btAvailable
                        text: "\uf294" + (root.btHeadline() !== "" ? "  " + root.btHeadline() : "")
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        color: btMouse.containsMouse ? root.horizon
                               : (!root.btOn ? root.fgDim : (root.btConnectedCount() > 0 ? root.horizon : root.fgMuted))
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: btMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    root.launch("kcmshell6 kcm_bluetooth", "blueman-manager");
                                } else {
                                    bar.btX = btIcon.mapToItem(null, btIcon.width / 2, 0).x;
                                    root.mediaOpen = false;
                                    bar.trayMenuOpen = false;
                                    bar.btOpen = !bar.btOpen;
                                }
                            }
                        }
                    }

                    // cpu
                    Text {
                        text: "\uf2db  " + root.cpuUsage + "%"
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        color: root.fgMuted
                    }

                    // memory
                    Text {
                        text: "\uf1c0  " + root.memUsage + "%"
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        color: root.fgMuted
                    }

                    // battery: calm, amber at 30%, blinking red at 15%
                    Text {
                        visible: root.hasBattery
                        text: root.batteryIcon() + "  " + root.batPct + "%"
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        color: root.batCritical ? root.red : (root.batWarning ? root.amber : root.fgMuted)
                        opacity: (root.batCritical && root.blinkOff) ? 0.35 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 450 } }
                    }

                    // system tray
                    Row {
                        visible: trayRepeater.count > 0
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            id: trayRepeater
                            model: SystemTray.items

                            delegate: Item {
                                id: trayItem
                                required property var modelData
                                // an app whose tray entry can't report an icon is a dead/ghost entry -> don't draw a blank slot
                                visible: (modelData.icon || "") !== ""

                                // Keep this app's menu open in the background. Apps that reset or drop their menu
                                // when it is closed (Chromium/Electron/Steam) otherwise come back EMPTY on the next open.
                                QsMenuOpener { menu: trayItem.modelData.menu }
                                width: Math.round(14 * root.uiScale)
                                height: Math.round(14 * root.uiScale)

                                IconImage {
                                    anchors.fill: parent
                                    source: trayItem.modelData.icon
                                    opacity: trayMouse.containsMouse ? 1.0 : 0.75
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
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
                                            if (it.onlyMenu && it.hasMenu) bar.openTrayMenu(it, x);
                                            else it.activate();
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            it.secondaryActivate();
                                        } else if (it.hasMenu) {
                                            bar.openTrayMenu(it, x);
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
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            onClicked: root.launch("qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptAll", "wlogout")
                        }
                    }
                }
            }

            // ───────────── now-playing popup (click the clock) ─────────────
            LazyLoader {
            active: root.mediaOpen
            PopupWindow {
                id: media
                anchor.window: bar
                anchor.rect.x: bar.width / 2 - width / 2
                anchor.rect.y: bar.height + 8 - 20      // 20 = shadow room above the card
                implicitWidth: 496                      // 440 card + 2*28 shadow room
                implicitHeight: 242                     // 188 card + 20 top + 34 bottom
                visible: root.mediaOpen
                color: "transparent"
                grabFocus: !root.isHypr                          // KDE & others: standard popup grab
                onVisibleChanged: if (!visible) root.mediaOpen = false

                // click anywhere outside (except the bar itself) to dismiss
                HyprlandFocusGrab {
                    windows: [media, bar]
                    active: root.isHypr && root.mediaOpen
                    onCleared: root.mediaOpen = false
                }

                // keep the elapsed time ticking — only while open AND playing
                Timer {
                    interval: 1000
                    repeat: true
                    running: media.visible && root.playing
                    onTriggered: if (root.player) root.player.positionChanged()
                }

                Rectangle {
                    id: panel
                    x: 28; y: 20
                    width: 440; height: 188
                    radius: 16
                    color: Qt.alpha(root.bgBase, 0.95)
                    border.width: 1
                    border.color: Qt.alpha(root.slate, 0.8)
                    opacity: 0
                    Component.onCompleted: opacity = 1
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    // ── soft shadow (stacked translucent layers, drawn behind the card) ──
                    Item {
                        z: -1
                        anchors.fill: parent

                        Repeater {
                            model: 10

                            delegate: Rectangle {
                                required property int index
                                readonly property real spread: (index + 1) * 2.4
                                x: -spread
                                y: -spread + 6                      // nudged down, light from above
                                width: parent.width + spread * 2
                                height: parent.height + spread * 2
                                radius: panel.radius + spread
                                color: Qt.rgba(0, 0, 0, 0.035)
                            }
                        }
                    }

                    // ── visualizer: rises from the bottom, BEHIND the song text ──
                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: panel.radius - 1
                        color: "transparent"
                        opacity: (root.cavaActive && root.playing) ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 400 } }

                        Row {
                            id: vizRow
                            // full height: each slot below is a full-height column,
                            // so bars can sit on the bottom edge and grow UP
                            height: parent.height
                            spacing: 5

                            readonly property int count: Math.max(1, root.cavaBars.length)
                            readonly property real barW: (parent.width - spacing * (count - 1)) / count

                            Repeater {
                                model: root.cavaBars.length

                                delegate: Item {
                                    id: slot
                                    required property int index
                                    // gated by playback state: bars fall to flat immediately on pause/stop
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
                                        Behavior on height { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
                                    }
                                }
                            }
                        }
                    }

                    // ── cover: real artwork if the player provides it, otherwise a music-note tile ──
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
                                Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
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
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: root.playing ? 0 : 1   // optical centering for the play triangle
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
            // Quickshell's built-in display() asks Qt for a *native* menu, which often
            // never appears on Wayland — so we draw the entries ourselves.
            LazyLoader {
                active: bar.trayMenuOpen

                PopupWindow {
                    id: trayMenu
                    anchor.window: bar
                    anchor.rect.x: Math.max(4, Math.min(bar.width - width - 4, bar.trayMenuX - width / 2))
                    anchor.rect.y: bar.height + 8 - 14
                    implicitWidth: 284                       // 240 card + 2*22 shadow room
                    implicitHeight: menuCard.height + 44     // 14 top + 30 bottom
                    visible: bar.trayMenuOpen
                    color: "transparent"
                    grabFocus: !root.isHypr
                    onVisibleChanged: if (!visible) bar.trayMenuOpen = false

                    HyprlandFocusGrab {
                        windows: [trayMenu, bar]
                        active: root.isHypr && bar.trayMenuOpen
                        onCleared: bar.trayMenuOpen = false
                    }

                    QsMenuOpener { id: menuOpener; menu: bar.trayMenuHandle }

                    // nothing to show after half a second -> give up and release the popup grab
                    Timer {
                        interval: 500
                        running: true
                        onTriggered: if (menuOpener.children.values.length === 0 && bar.trayMenuStack.length === 0) bar.trayMenuOpen = false
                    }

                    Rectangle {
                        id: menuCard
                        x: 22; y: 14
                        width: 240
                        height: menuCol.implicitHeight + 16
                        radius: 12
                        color: Qt.alpha(root.bgBase, 0.96)
                        border.width: 1
                        border.color: Qt.alpha(root.slate, 0.8)
                        opacity: menuOpener.children.values.length > 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        // soft shadow
                        Item {
                            z: -1
                            anchors.fill: parent
                            Repeater {
                                model: 8
                                delegate: Rectangle {
                                    required property int index
                                    readonly property real spread: (index + 1) * 2.4
                                    x: -spread
                                    y: -spread + 5
                                    width: parent.width + spread * 2
                                    height: parent.height + spread * 2
                                    radius: menuCard.radius + spread
                                    color: Qt.rgba(0, 0, 0, 0.035)
                                }
                            }
                        }

                        Column {
                            id: menuCol
                            x: 8; y: 8
                            width: parent.width - 16
                            spacing: 2

                            // "Back" row, only inside a submenu
                            Item {
                                visible: bar.trayMenuStack.length > 0
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
                                    font.pixelSize: root.fontSize
                                    color: root.fgMuted
                                }
                                MouseArea {
                                    id: backMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        const st = bar.trayMenuStack.slice();
                                        bar.trayMenuHandle = st.pop();
                                        bar.trayMenuStack = st;
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

                                    // separator
                                    Rectangle {
                                        visible: entry.modelData.isSeparator
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        height: 1
                                        color: Qt.alpha(root.slateHi, 0.5)
                                    }

                                    // hover highlight
                                    Rectangle {
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

                                        // checkbox / radio tick
                                        Text {
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
                                            font.pixelSize: root.fontSize
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
                                                bar.trayMenuStack = bar.trayMenuStack.concat([bar.trayMenuHandle]);
                                                bar.trayMenuHandle = entry.modelData;
                                            } else {
                                                entry.modelData.triggered();
                                                bar.trayMenuOpen = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ───────────── bluetooth popup (KDE-style device list) ─────────────
            LazyLoader {
                active: bar.btOpen

                PopupWindow {
                    id: btPopup
                    anchor.window: bar
                    anchor.rect.x: Math.max(4, Math.min(bar.width - width - 4, bar.btX - width / 2))
                    anchor.rect.y: bar.height + 8 - 14
                    implicitWidth: 304                       // 260 card + 2*22 shadow room
                    implicitHeight: btCard.height + 44       // 14 top + 30 bottom
                    visible: bar.btOpen
                    color: "transparent"
                    grabFocus: !root.isHypr
                    onVisibleChanged: if (!visible) bar.btOpen = false

                    HyprlandFocusGrab {
                        windows: [btPopup, bar]
                        active: root.isHypr && bar.btOpen
                        onCleared: bar.btOpen = false
                    }

                    Rectangle {
                        id: btCard
                        x: 22; y: 14
                        width: 260
                        height: btCol.implicitHeight + 20
                        radius: 12
                        color: Qt.alpha(root.bgBase, 0.96)
                        border.width: 1
                        border.color: Qt.alpha(root.slate, 0.8)
                        opacity: 0
                        Component.onCompleted: opacity = 1
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        // soft shadow
                        Item {
                            z: -1
                            anchors.fill: parent
                            Repeater {
                                model: 8
                                delegate: Rectangle {
                                    required property int index
                                    readonly property real spread: (index + 1) * 2.4
                                    x: -spread
                                    y: -spread + 5
                                    width: parent.width + spread * 2
                                    height: parent.height + spread * 2
                                    radius: btCard.radius + spread
                                    color: Qt.rgba(0, 0, 0, 0.035)
                                }
                            }
                        }

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
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        y: 3
                                        width: 14; height: 14
                                        radius: 7
                                        x: root.btOn ? btSwitch.width - width - 3 : 3
                                        color: root.btOn ? root.horizon : root.fgDim
                                        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
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

                            // footer: system bluetooth settings (pairing new devices lives there)
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
                                        root.launch("kcmshell6 kcm_bluetooth", "blueman-manager");
                                        bar.btOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ───────────── hover strip: touch the top edge to bring the bar back ─────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            // Stays mapped at all times: while the bar is shown it grows to fill the gap above the bar,
            // so resting the pointer at the edge keeps the bar open instead of hide/show/hide/show...
            implicitHeight: root.barShown ? Math.round(6 * root.uiScale) : 2
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: root.hidesAtAll

            Item {
                anchors.fill: parent
                HoverHandler { onHoveredChanged: root.edgeHovered = hovered }
            }
        }
    }
}

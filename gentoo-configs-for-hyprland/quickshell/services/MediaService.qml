pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// MPRIS via Quickshell's native D-Bus integration (Spotify, Firefox, Chromium, mpv, ...).
// Prefers whichever player is currently playing; can be pinned manually.
Singleton {
    id: root

    property var pinned: null
    readonly property var player: pick(Mpris.players.values, pinned)

    function pick(list, pin) {
        if (pin && list.indexOf(pin) >= 0) return pin;
        for (let i = 0; i < list.length; i++)
            if (list[i].isPlaying) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string title: player && player.trackTitle ? player.trackTitle : (player ? player.identity : "")
    readonly property string artist: player && player.trackArtist ? player.trackArtist : ""
    readonly property string album: player && player.trackAlbum ? player.trackAlbum : ""
    readonly property string identity: player ? player.identity : ""
    readonly property real length: player && player.lengthSupported ? player.length : 0
    readonly property real position: player && player.positionSupported ? player.position : 0
    readonly property bool canSeek: player ? player.canSeek : false
    readonly property bool canPrev: player ? player.canGoPrevious : false
    readonly property bool canNext: player ? player.canGoNext : false
    readonly property bool volumeSupported: player ? player.volumeSupported : false
    readonly property real volume: player && player.volumeSupported ? player.volume : 0
    readonly property int playerCount: Mpris.players.values.length

    // ── album art ──
    // Remote (https) art is downloaded with curl into /tmp because Qt may lack SSL support.
    // If the player sends no art, yt-dlp is asked for the page's thumbnail as a fallback.
    readonly property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
    property string art: ""

    onArtUrlChanged: artDebounce.restart()
    onTitleChanged: artDebounce.restart()
    onArtistChanged: artDebounce.restart()
    Component.onCompleted: artDebounce.restart()
    Timer { id: artDebounce; interval: 200; onTriggered: root.fetchArt() }

    // Art sources, fastest first:
    //  1. file:// art (Firefox): wait for it, copy to /tmp           -> instant
    //  2. http(s):// art (Spotify, YouTube...): curl                  -> fast
    //  3. yt-dlp (page URL, else search by title); result cached by title in ~/.cache/qs-glass
    function fetchArt() {
        artProc.running = false;
        art = "";
        if (!hasPlayer) return;
        const script = [
            'cache="$HOME/.cache/qs-glass"; mkdir -p "$cache"',
            'url="$1"; title="$2"; artist="$3"; art="$4"',
            'case "$art" in',
            '  file://*)',
            '    p="${art#file://}"',
            '    for i in 1 2 3 4 5 6 7 8 9 10 11 12; do [ -s "$p" ] && break; sleep 0.25; done',
            '    if [ -s "$p" ]; then',
            '      f=/tmp/qs-glass-art-$(stat -c %Y-%s "$p")-$(printf %s "$p" | md5sum | cut -c1-12)',
            '      cp -f "$p" "$f" && echo "$f" && exit 0',
            '    fi;;',
            '  http*)',
            '    f=/tmp/qs-glass-art-$(printf %s "$art" | md5sum | cut -d" " -f1)',
            '    [ -s "$f" ] || curl -sfL --max-time 10 -o "$f" "$art"',
            '    [ -s "$f" ] && echo "$f" && exit 0;;',
            'esac',
            '[ -n "$title" ] || exit 0',
            'key=$(printf %s "$title|$artist" | md5sum | cut -d" " -f1)',
            't=$(cat "$cache/$key" 2>/dev/null)',
            'if [ -z "$t" ]; then',
            '  get() { yt-dlp --no-warnings --no-playlist --skip-download --get-thumbnail "$1" 2>/dev/null | tail -n1; }',
            '  case "$url" in http*/you/*|http*/likes*|http*/feed*|"") ;; http*) t=$(get "$url");; esac',
            '  if [ -z "$t" ]; then',
            '    case "$url" in *soundcloud*) pre=scsearch1;; *) pre=ytsearch1;; esac',
            '    t=$(get "$pre:$title $artist")',
            '  fi',
            '  [ -n "$t" ] && printf %s "$t" > "$cache/$key"',
            'fi',
            '[ -n "$t" ] || exit 0',
            'f=/tmp/qs-glass-art-$(printf %s "$t" | md5sum | cut -d" " -f1)',
            '[ -s "$f" ] || curl -sfL --max-time 15 -o "$f" "$t"',
            '[ -s "$f" ] && echo "$f"'
        ].join("\n");
        const pageUrl = player && player.metadata && player.metadata["xesam:url"] ? String(player.metadata["xesam:url"]) : "";
        artProc.command = ["sh", "-c", script, "sh", pageUrl, title, artist, artUrl];
        artProc.running = true;
    }

    Process {
        id: artProc
        stdout: StdioCollector {
            onStreamFinished: { const t = text.trim(); root.art = t === "" ? "" : (t.startsWith("/") ? "file://" + t : t); }
        }
    }

    // ── controls ──
    function toggle() { if (player) player.togglePlaying(); }
    function next() { if (player && player.canGoNext) player.next(); }
    function previous() { if (player && player.canGoPrevious) player.previous(); }
    function seek(sec) { if (player && player.canSeek) player.position = Math.max(0, Math.min(length, sec)); }
    function setVolume(v) { if (player && player.volumeSupported) player.volume = Math.max(0, Math.min(1, v)); }
    function cycle() {
        const list = Mpris.players.values;
        if (list.length < 2) return;
        pinned = list[(list.indexOf(player) + 1) % list.length];
    }

    function fmt(sec) {
        const s = Math.max(0, Math.floor(sec));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // MPRIS doesn't push position updates; poke the property while playing.
    Timer {
        running: root.isPlaying
        interval: 500
        repeat: true
        onTriggered: if (root.player) root.player.positionChanged()
    }
}

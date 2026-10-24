// Quickshell auto-hide helper — loaded into KWin by shell.qml (Plasma only).
// Tells Quickshell whenever a real window starts / stops reaching into the bar's strip
// at the top of the screen, by sending a harmless D-Bus call that Quickshell listens for.
// __STRIP__ is replaced by shell.qml with the bar's real height (it follows uiScale).

var STRIP = __STRIP__;
var last = null;
var lastWho = "";

function reaches(w) {
    if (!w || !w.normalWindow || w.minimized) return false;
    if (w.skipTaskbar) return false;                           // helper windows (screen-share bridges, etc.)
    // only windows on the desktop you're looking at
    if (!w.onAllDesktops && w.desktops && w.desktops.indexOf(workspace.currentDesktop) < 0) return false;
    var g = w.frameGeometry;
    if (g.width < 120 || g.height < 80) return false;          // tiny / invisible windows don't count
    var top = (w.output && w.output.geometry) ? w.output.geometry.y : 0;
    return (g.y - top) < STRIP && (g.y + g.height) > top;
}

function who(w) {                                              // bus-name-safe label, for debugging only
    var s = ((w.resourceClass || "") + "_" + (w.caption || "")).replace(/[^A-Za-z0-9_]/g, "_");
    return "w_" + s.substring(0, 60);
}

function check() {
    var list = workspace.windowList();
    var hit = null;
    for (var i = 0; i < list.length; i++) {
        if (reaches(list[i])) { hit = list[i]; break; }
    }
    var now = hit !== null;
    var name = now ? who(hit) : "";
    if (now !== last) {                       // only talk when something actually changed
        last = now;
        callDBus("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                 "NameHasOwner", "quickshell.dodge." + now);
    }
    if (name !== lastWho) {                   // which window is the culprit (shown by the debug command)
        lastWho = name;
        if (now) callDBus("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                          "NameHasOwner", "quickshell.dodgewho." + name);
    }
}

function hook(w) {
    if (!w || !w.normalWindow) return;
    w.frameGeometryChanged.connect(check);
    w.minimizedChanged.connect(check);
    w.desktopsChanged.connect(check);
    w.fullScreenChanged.connect(check);
}

workspace.windowAdded.connect(function (w) { hook(w); check(); });
workspace.windowRemoved.connect(check);
workspace.currentDesktopChanged.connect(check);

var all = workspace.windowList();
for (var i = 0; i < all.length; i++) hook(all[i]);
check();

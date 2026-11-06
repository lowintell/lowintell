pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// NetworkManager via nmcli. `nmcli monitor` makes it reactive; one poll command gathers
// radio state, devices and the Wi-Fi list so each refresh is a single process.
Singleton {
    id: root

    property bool wifiEnabled: false
    property string kind: "none"          // wifi | ethernet | none
    property string ssid: ""
    property int signal: 0
    property var networks: []

    readonly property bool connected: kind !== "none"
    readonly property string label: kind === "wifi" ? ssid
        : kind === "ethernet" ? "Ethernet"
        : wifiEnabled ? "Not connected" : "Wi-Fi off"
    readonly property string icon: {
        if (kind === "ethernet") return "lan";
        if (!wifiEnabled) return "wifi_off";
        if (kind === "none") return "signal_wifi_off";
        return signal > 66 ? "wifi" : signal > 33 ? "wifi_2_bar" : "wifi_1_bar";
    }

    function split(line) {
        return line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"));
    }

    function parse(text) {
        const parts = text.split("@@\n");
        if (parts.length < 3) return;
        wifiEnabled = parts[0].trim() === "enabled";

        let eth = false, wifiConn = "";
        for (const line of parts[1].trim().split("\n")) {
            const f = split(line);
            if (f.length < 4 || f[2] !== "connected") continue;
            if (f[1] === "ethernet") eth = true;
            if (f[1] === "wifi") wifiConn = f[3];
        }

        const best = {};
        let active = null;
        for (const line of parts[2].trim().split("\n")) {
            if (line === "") continue;
            const f = split(line);
            if (f.length < 3 || f[1] === "") continue;
            const entry = { ssid: f[1], signal: parseInt(f[2]) || 0, secure: (f[3] || "") !== "", inUse: f[0] === "*" };
            if (entry.inUse) active = entry;
            if (!best[entry.ssid] || best[entry.ssid].signal < entry.signal) best[entry.ssid] = entry;
        }
        const list = Object.values(best).sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
        networks = list;

        if (eth) { kind = "ethernet"; }
        else if (active || wifiConn !== "") {
            kind = "wifi";
            ssid = active ? active.ssid : wifiConn;
            signal = active ? active.signal : 0;
        } else { kind = "none"; ssid = ""; signal = 0; }
    }

    function refresh() { if (!poll.running) poll.running = true; }
    function setWifi(on) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        settle.restart();
    }
    function scan() {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
        settle.restart();
    }
    function connectTo(name) {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", name]);
        settle.restart();
    }

    Process {
        id: poll
        command: ["sh", "-c",
            "nmcli radio wifi; echo @@; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev; echo @@; " +
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: debounce.restart() }
    }

    Timer { id: debounce; interval: 500; onTriggered: root.refresh() }
    Timer { id: settle; interval: 2500; onTriggered: root.refresh() }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Connections {
        target: UiState
        function onActiveChanged() { if (UiState.active === "quick" && root.wifiEnabled) root.scan(); }
    }
}

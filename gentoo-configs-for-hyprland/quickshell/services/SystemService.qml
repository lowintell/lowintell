pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// CPU/RAM are sampled cheaply from /proc every 2s (always, the bar shows them).
// Temperature, GPU, network and disk are only sampled while the System panel is open.
Singleton {
    id: root

    readonly property bool detailed: UiState.active === "system"
    readonly property int histLen: 60

    property real cpu: 0
    property real ram: 0
    property real ramUsed: 0      // GiB
    property real ramTotal: 0     // GiB
    property var cpuHist: []
    property var ramHist: []

    property real cpuTemp: -1
    property real netDown: 0      // bytes/s
    property real netUp: 0
    property var netDownHist: []
    property var netUpHist: []

    property real gpu: -1
    property real gpuTemp: -1
    property real vramUsed: 0     // MiB
    property real vramTotal: 0
    property var gpuHist: []

    property var disks: []

    property real _idle: 0
    property real _total: 0
    property real _rx: -1
    property real _tx: -1
    property real _t: 0

    function push(arr, v) {
        const a = arr.slice();
        a.push(v);
        if (a.length > histLen) a.shift();
        return a;
    }

    function parseStat(text) {
        const f = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (f.length < 5) return;
        const idle = f[3] + (f[4] || 0);
        let total = 0;
        for (let i = 0; i < Math.min(f.length, 8); i++) total += f[i];
        if (_total > 0) {
            const dt = total - _total, di = idle - _idle;
            if (dt > 0) {
                cpu = Math.max(0, Math.min(100, (1 - di / dt) * 100));
                cpuHist = push(cpuHist, cpu);
            }
        }
        _idle = idle;
        _total = total;
    }

    function parseMem(text) {
        const t = text.match(/MemTotal:\s+(\d+)/);
        const a = text.match(/MemAvailable:\s+(\d+)/);
        if (!t || !a) return;
        const total = Number(t[1]), avail = Number(a[1]);
        ramTotal = total / 1048576;
        ramUsed = (total - avail) / 1048576;
        ram = (total - avail) / total * 100;
        ramHist = push(ramHist, ram);
    }

    function parseNet(text) {
        const lines = text.split("\n").slice(2);
        let rx = 0, tx = 0;
        for (const line of lines) {
            const idx = line.indexOf(":");
            if (idx < 0) continue;
            const name = line.slice(0, idx).trim();
            if (name === "lo" || /^(veth|docker|br-|virbr)/.test(name)) continue;
            const f = line.slice(idx + 1).trim().split(/\s+/);
            rx += Number(f[0]);
            tx += Number(f[8]);
        }
        const now = Date.now();
        if (_rx >= 0 && now > _t) {
            const dt = (now - _t) / 1000;
            netDown = Math.max(0, (rx - _rx) / dt);
            netUp = Math.max(0, (tx - _tx) / dt);
            netDownHist = push(netDownHist, netDown);
            netUpHist = push(netUpHist, netUp);
        }
        _rx = rx; _tx = tx; _t = now;
    }

    function fmtBytes(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB/s";
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s";
        if (b >= 1024) return Math.round(b / 1024) + " KB/s";
        return Math.round(b) + " B/s";
    }
    function fmtSize(b) {
        if (b >= 1099511627776) return (b / 1099511627776).toFixed(1) + " TB";
        if (b >= 1073741824) return (b / 1073741824).toFixed(0) + " GB";
        return (b / 1048576).toFixed(0) + " MB";
    }

    function refreshDetail() {
        if (!tempP.running) tempP.running = true;
        if (Config.gpuPolling && !gpuP.running) gpuP.running = true;
    }
    function refreshDisks() { if (!diskP.running) diskP.running = true; }

    onDetailedChanged: {
        if (detailed) { refreshDetail(); refreshDisks(); }
        else { _rx = -1; }
    }

    FileView { id: statF; path: "/proc/stat"; onLoaded: root.parseStat(text()) }
    FileView { id: memF; path: "/proc/meminfo"; onLoaded: root.parseMem(text()) }
    FileView { id: netF; path: "/proc/net/dev"; onLoaded: root.parseNet(text()) }

    Timer {
        interval: root.detailed ? 1000 : 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statF.reload();
            memF.reload();
            if (root.detailed) netF.reload();
        }
    }

    Timer {
        interval: 2500
        running: root.detailed
        repeat: true
        onTriggered: root.refreshDetail()
    }
    Timer {
        interval: 30000
        running: root.detailed
        repeat: true
        onTriggered: root.refreshDisks()
    }

    Process {
        id: tempP
        command: ["sh", "-c",
            "for z in /sys/class/thermal/thermal_zone*; do t=$(cat $z/type 2>/dev/null); case $t in x86_pkg_temp|k10temp*|cpu*|soc*) cat $z/temp; exit;; esac; done; " +
            "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name 2>/dev/null) in coretemp|k10temp|zenpower) cat $h/temp1_input; exit;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim());
                root.cpuTemp = isNaN(v) ? -1 : v / 1000;
            }
        }
    }

    Process {
        id: gpuP
        command: ["sh", "-c",
            "if command -v nvidia-smi >/dev/null 2>&1; then " +
            "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits | head -n1; " +
            "else for c in /sys/class/drm/card*/device; do if [ -r $c/gpu_busy_percent ]; then " +
            "echo \"$(cat $c/gpu_busy_percent),$(awk '{print $1/1000}' $c/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1),$(( $(cat $c/mem_info_vram_used) / 1048576 )),$(( $(cat $c/mem_info_vram_total) / 1048576 ))\"; break; fi; done; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",").map(s => parseFloat(s));
                if (p.length >= 4 && !isNaN(p[0])) {
                    root.gpu = p[0];
                    root.gpuTemp = isNaN(p[1]) ? -1 : p[1];
                    root.vramUsed = p[2];
                    root.vramTotal = p[3];
                    root.gpuHist = root.push(root.gpuHist, p[0]);
                } else {
                    root.gpu = -1;
                }
            }
        }
    }

    Process {
        id: diskP
        command: ["df", "-B1", "--output=target,size,used,pcent",
                  "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "squashfs", "-x", "overlay"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                const lines = text.trim().split("\n").slice(1);
                for (const line of lines) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 4) continue;
                    const pct = parseInt(f[f.length - 1]);
                    const used = Number(f[f.length - 2]);
                    const size = Number(f[f.length - 3]);
                    const mount = f.slice(0, f.length - 3).join(" ");
                    if (!(mount === "/" || mount === "/home" || mount === "/boot" || mount === "/boot/efi" ||
                          mount.startsWith("/mnt") || mount.startsWith("/run/media"))) continue;
                    out.push({ mount: mount, size: size, used: used, pct: isNaN(pct) ? 0 : pct });
                }
                root.disks = out.slice(0, 4);
            }
        }
    }
}

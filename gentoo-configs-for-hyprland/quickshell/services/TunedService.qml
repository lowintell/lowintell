pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Power profiles through tuned (tuned-adm). Replaces power-profiles-daemon.
Singleton {
    id: root

    property string active: ""
    property var available: []
    property bool failed: false

    function refresh() {
        if (!activeP.running) activeP.running = true;
        if (!listP.running) listP.running = true;
    }

    function set(name) {
        failed = false;
        active = name;                       // optimistic; corrected by refresh() if it fails
        setP.command = Config.tunedElevate.concat(["tuned-adm", "profile", name]);
        setP.running = true;
    }

    Process {
        id: activeP
        command: ["tuned-adm", "active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Current active profile:\s*(\S+)/);
                if (m) root.active = m[1];
            }
        }
    }

    Process {
        id: listP
        command: ["tuned-adm", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const m = line.match(/^-\s+(\S+)/);
                    if (m) out.push(m[1]);
                }
                root.available = out;
            }
        }
    }

    Process {
        id: setP
        onExited: code => { root.failed = code !== 0; root.refresh(); }
    }

    Component.onCompleted: refresh()
    Connections {
        target: UiState
        function onActiveChanged() { if (UiState.active === "quick") root.refresh(); }
    }
}

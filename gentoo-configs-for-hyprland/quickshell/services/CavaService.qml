pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// Real spectrum data from cava (raw ascii output). Runs only while something is playing.
Singleton {
    id: root

    property var values: []
    property bool active: false

    Process {
        id: cava
        command: Config.cavaCommand
        running: MediaService.isPlaying
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(";");
                const out = [];
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i] === "") continue;
                    out.push(Number(parts[i]));
                }
                if (out.length > 0) {
                    root.values = out;
                    root.active = true;
                }
            }
        }
        onRunningChanged: if (!running) { root.active = false; root.values = []; }
    }
}

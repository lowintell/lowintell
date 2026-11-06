pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink volume/mute through PipeWire (works with pipewire-pulse/wireplumber).
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property string deviceName: sink ? (sink.description || sink.name) : "No output"

    readonly property string icon: {
        if (!ready || muted || volume <= 0) return muted ? "volume_off" : "volume_mute";
        return volume < 0.5 ? "volume_down" : "volume_up";
    }

    function setVolume(v) {
        if (!ready) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted; }
}

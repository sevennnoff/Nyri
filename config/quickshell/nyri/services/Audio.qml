pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream && !(n.name ?? "").startsWith("nyri_eq"))
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream
                                                                    && !(n.name ?? "").endsWith(".monitor"))
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream
                                                                    && n.properties["media.class"] === "Stream/Output/Audio"
                                                                    && !(n.name ?? "").startsWith("nyri_eq"))

    function label(node) {
        return node?.description || node?.nickname || node?.name || "";
    }

    function deviceIcon(node) {
        const n = ((node?.name ?? "") + " " + (node?.description ?? "")).toLowerCase();
        if (n.includes("bluez")) return "headphones";
        if (n.includes("headphone") || n.includes("headset")) return "headphones";
        if (n.includes("hdmi") || n.includes("displayport")) return "tv";
        if (!node?.isSink) return "mic";
        return "speaker";
    }

    function setDefault(node) {
        if (node.isSink) Pipewire.preferredDefaultAudioSink = node;
        else Pipewire.preferredDefaultAudioSource = node;
    }

    readonly property string icon: muted ? "volume_off"
                                  : volume < 0.01 ? "volume_mute"
                                  : volume < 0.5 ? "volume_down" : "volume_up"

    function setVolume(v) {
        if (sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMic() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    property bool settled: false
    Timer {
        running: true
        interval: 2000
        onTriggered: root.settled = true
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { if (root.settled) Osd.show("volume") }
        function onMutedChanged() { if (root.settled) Osd.show("volume") }
    }

    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() { if (root.settled) Osd.show("mic") }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int wanted: 0
    readonly property var player: Media.player
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property real length: player?.length ?? 0
    readonly property string key: artist + "\u0001" + title

    property var cache: ({})
    readonly property var entry: cache[key] ?? null
    readonly property var lines: entry ? (entry.synced.length ? entry.synced : entry.plain.map(t => ({ t: -1, text: t }))) : []
    readonly property bool synced: (entry?.synced.length ?? 0) > 0
    readonly property bool loading: fetch.running
    readonly property bool none: entry?.none ?? false

    property real basePos: 0
    property real baseAt: Date.now()
    property real now: Date.now()
    readonly property real position: player?.isPlaying ? basePos + (now - baseAt) / 1000 : basePos
    Connections {
        target: root.player
        function onPositionChanged() { root.basePos = root.player.position; root.baseAt = Date.now(); }
    }
    Timer {
        running: root.wanted > 0 && root.synced && (root.player?.isPlaying ?? false)
        interval: 200
        repeat: true
        onTriggered: {
            root.now = Date.now();
            if (root.now - root.baseAt > 2000) root.player.positionChanged();
        }
    }
    readonly property int current: {
        if (!synced) return -1;
        const p = position + 0.25;
        let i = -1;
        for (let k = 0; k < lines.length; k++) { if (lines[k].t <= p) i = k; else break; }
        return i;
    }
    function seek(i) {
        const l = lines[i];
        if (l && l.t >= 0 && player?.canSeek) { player.position = l.t; basePos = l.t; baseAt = Date.now(); }
    }

    onKeyChanged: maybeFetch()
    onWantedChanged: maybeFetch()
    function maybeFetch() {
        if (wanted <= 0 || !title || cache[key] || fetch.running) return;
        const q = s => encodeURIComponent(s);
        let url = "https://lrclib.net/api/get?track_name=" + q(title) + "&artist_name=" + q(artist);
        if (album) url += "&album_name=" + q(album);
        if (length > 0) url += "&duration=" + Math.round(length);
        fetch.asked = key;
        fetch.search = false;
        fetch.command = ["curl", "-s", "-m", "8", "-A", "Nyri (github.com/yzewe/Nyri)", url];
        fetch.running = true;
    }

    function parse(obj) {
        const synced = [], plain = [];
        for (const line of (obj?.syncedLyrics ?? "").split("\n")) {
            const m = line.match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/);
            if (m) synced.push({ t: +m[1] * 60 + +m[2], text: m[3] });
        }
        for (const line of (obj?.plainLyrics ?? "").split("\n")) plain.push(line);
        return { synced, plain: plain.filter((l, i) => l.trim() || (i > 0 && plain[i - 1].trim())), none: !synced.length && !plain.some(l => l.trim()) };
    }

    Process {
        id: fetch
        property string asked: ""
        property bool search: false
        stdout: StdioCollector {
            onStreamFinished: {
                let data = null;
                try { data = JSON.parse(text); } catch (e) {}
                if (Array.isArray(data)) data = data.find(d => d.syncedLyrics) ?? data[0] ?? null;
                const got = data && (data.syncedLyrics || data.plainLyrics) ? root.parse(data) : null;
                if (!got && !fetch.search) {
                    fetch.search = true;
                    fetch.command = ["curl", "-s", "-m", "8", "-A", "Nyri (github.com/yzewe/Nyri)",
                                     "https://lrclib.net/api/search?q=" + encodeURIComponent(root.artist + " " + root.title)];
                    Qt.callLater(() => fetch.running = true);
                    return;
                }
                const next = Object.assign({}, root.cache);
                next[fetch.asked] = got ?? { synced: [], plain: [], none: true };
                root.cache = next;
            }
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var chosen: null
    readonly property var player: (chosen && players.indexOf(chosen) >= 0 ? chosen : null) ?? players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property string rawArt: player?.trackArtUrl ?? ""
    property string art: ""
    onRawArtChanged: refreshArt()
    Component.onCompleted: refreshArt()
    Connections {
        target: root.player
        function onTrackArtUrlChanged() { root.refreshArt(); }
    }

    function refreshArt() {
        const url = rawArt;
        if (!url) { art = ""; return; }
        if (!url.startsWith("file:")) { art = url; return; }
        let path = url.slice("file://".length);
        try { path = decodeURIComponent(path); } catch (e) {}
        if (/\.(png|jpe?g|webp|gif|bmp|avif)$/i.test(path)) { art = "file://" + path; return; }
        artJob.running = false;
        artJob.path = path;
        artJob.rev++;
        artJob.running = true;
    }

    Process {
        id: artJob
        property string path: ""
        property int rev: 0
        command: ["python3", "-c", "
import os, sys, shutil
src, folder, rev = sys.argv[1], sys.argv[2], sys.argv[3]
b = open(src, 'rb').read(16)
ext = '.png' if b[:4] == bytes([137, 80, 78, 71]) else '.jpg' if b[:3] == bytes([255, 216, 255]) else '.webp' if b[8:12] == b'WEBP' else '.gif' if b[:4] == b'GIF8' else ''
if not ext:
    sys.exit(1)
for old in os.listdir(folder):
    if old.startswith('nyri-cover-') and not old.endswith(rev + ext):
        try: os.remove(os.path.join(folder, old))
        except OSError: pass
dest = os.path.join(folder, 'nyri-cover-' + rev + ext)
shutil.copyfile(src, dest)
print(dest)
", path, (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"), String(rev)]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path) root.art = "file://" + path;
            }
        }
    }
}

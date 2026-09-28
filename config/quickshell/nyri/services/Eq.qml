pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var bands: [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    readonly property bool on: Config.o.eq.on
    readonly property var gains: Config.o.eq.gains.length === 10 ? Config.o.eq.gains : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    readonly property var presets: [
        { id: "flat", label: "Ровно", g: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
        { id: "bass", label: "Бас", g: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0] },
        { id: "vocal", label: "Голос", g: [-2, -2, -1, 1, 3, 4, 3, 1, 0, -1] },
        { id: "treble", label: "Звонко", g: [0, 0, 0, 0, 0, 1, 2, 4, 5, 6] },
        { id: "v", label: "V-образно", g: [5, 4, 2, 0, -2, -2, 0, 2, 4, 5] },
        { id: "night", label: "Тихо ночью", g: [-4, -3, -1, 0, 1, 2, 1, 0, -2, -3] }
    ]
    readonly property string preset: presets.find(p => p.g.every((v, i) => Math.abs(v - gains[i]) < 0.01))?.id ?? ""

    function setOn(v) { Config.o.eq.on = v; }
    function setGain(i, db) {
        const g = gains.slice();
        g[i] = Math.round(Math.max(-12, Math.min(12, db)) * 2) / 2;
        Config.o.eq.gains = g;
    }
    function usePreset(id) { const p = presets.find(x => x.id === id); if (p) Config.o.eq.gains = p.g.slice(); }

    Process {
        id: filter
        running: root.on
        command: [Paths.bin + "/nyri-eq", "run", ...root.gains.map(String)]
    }
    onGainsChanged: if (on) apply.restart()
    Timer {
        id: apply
        interval: 120
        onTriggered: Quickshell.execDetached([Paths.bin + "/nyri-eq", "set", ...root.gains.map(String)])
    }
}

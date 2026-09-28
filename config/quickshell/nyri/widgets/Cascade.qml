import QtQuick
import qs.theme

FrameAnimation {
    id: root

    property real rise: 30
    property real step: 0.04
    property real damping: 0.68
    property real stiffness: 260
    property int most: 14

    property var moves: []
    property real t: 0

    function at(s) {
        if (s <= 0) return 1;
        const w = Math.sqrt(stiffness) * Motion.speed, z = damping, wd = w * Math.sqrt(1 - z * z);
        return Math.exp(-z * w * s) * (Math.cos(wd * s) + z * w / wd * Math.sin(wd * s));
    }

    function mover(item) {
        for (const tr of item.transform)
            if (tr.objectName === "cascade") return tr;
        const tr = Qt.createQmlObject('import QtQuick; Translate { objectName: "cascade" }', item);
        const list = [];
        for (const x of item.transform) list.push(x);
        list.push(tr);
        item.transform = list;
        return tr;
    }

    function play(col) {
        for (const m of moves) m.tr.y = 0;
        moves = [];
        if (!col || Motion.speed <= 0) return;
        let i = 0;
        for (const c of col.children) {
            if (!c.visible || c.height <= 0) continue;
            if (i >= most) break;
            const tr = mover(c);
            const r = rise * (1 + i * 0.12);
            tr.y = r;
            moves.push({ tr, r, delay: i * step });
            i++;
        }
        t = 0;
        running = moves.length > 0;
    }

    onTriggered: {
        t += Math.min(frameTime, 0.05);
        let done = true;
        for (const m of moves) {
            const s = t - m.delay;
            const x = at(s);
            const still = s > 0.15 && Math.abs(x) <= 0.002;
            if (!still) done = false;
            m.tr.y = still ? 0 : m.r * x;
        }
        if (done) {
            for (const m of moves) m.tr.y = 0;
            moves = [];
            running = false;
        }
    }
}

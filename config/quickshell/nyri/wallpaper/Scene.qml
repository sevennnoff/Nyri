import QtQuick
import Quickshell.Io
import qs.theme
import qs.services

Item {
    id: root

    property string file: ""
    property bool running: false
    property int fps: 30
    property var sc: null
    readonly property bool ready: sc !== null
    property real t: 0
    signal missing

    onFileChanged: { sc = null; t = 0; }
    function reload() { view.reload(); }
    FileView {
        id: view
        path: root.file
        onLoaded: {
            try { root.sc = JSON.parse(text()); } catch (e) { root.sc = null; }
            root.t = 0;
        }
        onLoadFailed: root.missing()
    }

    property real pace: 1
    readonly property real speed: Math.max(0.1, Motion.speed * (Config.o.wallpaper.pace ?? 1) * pace)
    onSpeedChanged: { const s = sc; sc = null; sc = s; }

    property Component wobble: Component {
        SequentialAnimation {
            id: w
            property QtObject target
            property string prop
            property real base: 0
            property real amp
            property int period: 4000
            property int delay: 0
            running: true
            paused: !root.running
            PauseAnimation { duration: w.delay }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: w.target; property: w.prop; to: w.base + w.amp; duration: w.period / 4; easing.type: Easing.OutSine }
                NumberAnimation { target: w.target; property: w.prop; to: w.base - w.amp; duration: w.period / 2; easing.type: Easing.InOutSine }
                NumberAnimation { target: w.target; property: w.prop; to: w.base; duration: w.period / 4; easing.type: Easing.InSine }
            }
        }
    }
    property Component dip: Component {
        SequentialAnimation {
            id: d
            property QtObject target
            property string prop
            property real depth
            property int period: 3000
            running: true
            paused: !root.running
            loops: Animation.Infinite
            NumberAnimation { target: d.target; property: d.prop; to: 1 - d.depth; duration: d.period / 2; easing.type: Easing.InOutSine }
            NumberAnimation { target: d.target; property: d.prop; to: 1; duration: d.period / 2; easing.type: Easing.InOutSine }
        }
    }
    property Component loop: Component {
        NumberAnimation {
            property string prop
            property int span: 10000
            property: prop
            duration: span
            loops: Animation.Infinite
            running: true
            paused: !root.running
        }
    }
    property Component drift: Component {
        SequentialAnimation {
            id: dr
            property QtObject target
            property real first
            property int firstSpan
            property real from
            property real to
            property int span
            running: true
            paused: !root.running
            NumberAnimation { target: dr.target; property: "x"; from: 0; to: dr.first; duration: dr.firstSpan }
            NumberAnimation { target: dr.target; property: "x"; from: dr.from; to: dr.to; duration: dr.span; loops: Animation.Infinite }
        }
    }
    property Component flipper: Component {
        SequentialAnimation {
            id: fl
            property Item node
            property int every: 20000
            property int delay: 0
            running: true
            paused: !root.running
            PauseAnimation { duration: fl.delay }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: fl.node; property: "flipF"; from: 0; to: 1; duration: 620 / root.speed; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                ScriptAction { script: { fl.node.flipN += 1; fl.node.flipF = 0; } }
                PauseAnimation { duration: Math.max(0, fl.every - 620 / root.speed) }
            }
        }
    }
    property Component cosine: Component {
        SequentialAnimation {
            id: cs
            property QtObject target
            property real phase
            property int period: 7000
            readonly property bool up: phase < Math.PI
            readonly property int lead: Math.round((up ? phase : phase - Math.PI) / (2 * Math.PI) * period)
            running: true
            paused: !root.running
            NumberAnimation { target: cs.target; property: "xScale"; to: cs.up ? 1 : 0; duration: cs.lead; easing.type: Easing.OutSine }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: cs.target; property: "xScale"; to: cs.up ? 0 : 1; duration: cs.period / 2; easing.type: Easing.InOutSine }
                NumberAnimation { target: cs.target; property: "xScale"; to: cs.up ? 1 : 0; duration: cs.period / 2; easing.type: Easing.InOutSine }
            }
        }
    }

    readonly property bool comets: (sc?.fx ?? []).some(f => f.k === "comets")
    property real last: 0
    Timer {
        running: root.running && root.ready && root.comets
        interval: Math.round(1000 / root.fps)
        repeat: true
        onRunningChanged: root.last = Date.now()
        onTriggered: {
            const now = Date.now();
            root.t += Math.min(0.1, (now - root.last) / 1000) * root.speed;
            root.last = now;
        }
    }

    Item {
        id: canvas
        visible: root.ready
        width: root.sc?.w ?? 0
        height: root.sc?.h ?? 0
        readonly property real k: root.ready ? Math.max(root.width / width, root.height / height) : 1
        x: (root.width - width * k) / 2
        y: (root.height - height * k) / 2
        transformOrigin: Item.TopLeft
        scale: k

        Rectangle { anchors.fill: parent; color: root.sc?.bg ?? "transparent" }

        Loader {
            active: !!root.sc?.grid
            sourceComponent: SceneNode {
                scene: root
                n: ({ p: [{ d: root.sc.grid.d, s: root.sc.grid.s, w: root.sc.grid.w, cap: "butt" }], r: 0, o: [0, 0], m: [] })
            }
        }

        Repeater {
            model: root.sc?.nodes ?? []
            SceneNode {
                required property var modelData
                scene: root
                n: modelData
            }
        }

        Repeater {
            model: (root.sc?.fx ?? []).filter(f => f.k === "comets")
            Item {
                id: comet
                required property var modelData
                readonly property real every: modelData.every
                readonly property int n: Math.floor(root.t / every)
                readonly property real local: root.t - n * every
                function rnd(i) { const v = Math.sin((n + 1) * 12.9898 + i * 78.233) * 43758.5453; return v - Math.floor(v); }
                readonly property real life: 1.1
                readonly property real q: Math.min(1, local / life)
                visible: root.t > 0 && local < life && rnd(3) < 0.75
                x: canvas.width * (0.15 + 0.7 * rnd(1)) + q * canvas.width * 0.22
                y: canvas.height * (0.05 + 0.4 * rnd(2)) + q * canvas.width * 0.22 * 0.45
                rotation: 24
                opacity: Math.sin(Math.PI * q)
                Rectangle {
                    x: -width
                    y: -height / 2
                    width: canvas.height * 0.12
                    height: canvas.height * 0.006
                    radius: height / 2
                    color: comet.modelData.c
                }
            }
        }
    }
}

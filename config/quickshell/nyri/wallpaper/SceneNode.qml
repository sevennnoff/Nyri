import QtQuick
import QtQuick.Shapes

Item {
    id: nd

    property var n: null
    property Item scene: null

    readonly property string kind: !n ? "" : n.g ? "group" : (n.t ?? "node")
    readonly property real ox: kind === "dot" ? n.x : (n?.o?.[0] ?? 0)
    readonly property real oy: kind === "dot" ? n.y : (n?.o?.[1] ?? 0)

    property real flipStep: 0
    property int flipN: 0
    property real flipF: 0
    property real orbA: 0
    property var orb: null
    property real hideBelow: -1

    visible: hideBelow < 0 || grow.xScale >= hideBelow
    transform: [
        Scale { id: grow; origin.x: nd.ox; origin.y: nd.oy; yScale: xScale },
        Scale { id: widen; origin.x: nd.ox; origin.y: nd.oy },
        Rotation { origin.x: nd.ox; origin.y: nd.oy; angle: nd.n?.r ?? 0 },
        Rotation { id: spin; origin.x: nd.ox; origin.y: nd.oy },
        Rotation { id: sway; origin.x: nd.ox; origin.y: nd.oy },
        Rotation { origin.x: nd.ox; origin.y: nd.oy; angle: nd.flipStep * (nd.flipN + nd.flipF) },
        Translate { id: bob },
        Translate { id: slide },
        Translate {
            x: nd.orb ? nd.orb.rx * (Math.cos(nd.orbA) - Math.cos(nd.orb.ph)) : 0
            y: nd.orb ? nd.orb.ry * (Math.sin(nd.orbA) - Math.sin(nd.orb.ph)) : 0
        }
    ]

    property bool started: false
    onNChanged: Qt.callLater(start)
    onSceneChanged: Qt.callLater(start)
    function start() {
        if (started || !n || !scene || !n.m || !n.m.length) return;
        started = true;
        const sp = scene.speed;
        const ms = s => Math.max(1, Math.round(s * 1000 / sp));
        const lead = m => ms((((m.ph ?? 0) % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI) / (2 * Math.PI) * m.p);
        for (const m of n.m) {
            switch (m.k) {
            case "spin":
                scene.loop.createObject(nd, { target: spin, prop: "angle", from: 0, to: m.v > 0 ? 360 : -360, span: ms(360 / Math.abs(m.v)) });
                break;
            case "sway":
                scene.wobble.createObject(nd, { target: sway, prop: "angle", amp: m.a, period: ms(m.p), delay: lead(m) });
                break;
            case "bob":
                if (m.dx) scene.wobble.createObject(nd, { target: bob, prop: "x", amp: m.dx, period: ms(m.p), delay: lead(m) });
                if (m.dy) scene.wobble.createObject(nd, { target: bob, prop: "y", amp: m.dy, period: ms(m.p), delay: lead(m) });
                break;
            case "breathe":
                scene.wobble.createObject(nd, { target: grow, prop: "xScale", base: 1, amp: m.a, period: ms(m.p), delay: lead(m) });
                break;
            case "stretch":
                scene.wobble.createObject(nd, { target: widen, prop: "xScale", base: 1, amp: m.a, period: ms(m.p), delay: lead(m) });
                break;
            case "twinkle":
                scene.dip.createObject(nd, { target: nd, prop: "opacity", depth: m.a, period: ms(m.p) });
                break;
            case "flip":
                flipStep = m.st;
                scene.flipper.createObject(nd, { node: nd, every: ms(m.e), delay: ms(m.ph) });
                break;
            case "scroll":
                scene.loop.createObject(nd, { target: slide, prop: "x", from: 0, to: m.v > 0 ? -m.P : m.P, span: ms(m.P / Math.abs(m.v)) });
                break;
            case "drift": {
                const far = m.W + 40 - m.x0, near = -(m.x0 + m.bw + 40), v = Math.abs(m.v);
                if (m.v > 0) scene.drift.createObject(nd, { target: slide, first: far, firstSpan: ms(far / v), from: near, to: far, span: ms((far - near) / v) });
                else scene.drift.createObject(nd, { target: slide, first: near, firstSpan: ms(-near / v), from: far, to: near, span: ms((far - near) / v) });
                break;
            }
            case "orbit":
                orb = m;
                orbA = m.ph;
                scene.loop.createObject(nd, { target: nd, prop: "orbA", from: m.ph, to: m.ph + (m.p > 0 ? 2 : -2) * Math.PI, span: ms(Math.abs(m.p)) });
                break;
            case "swell":
                grow.xScale = m.s0;
                scene.loop.createObject(nd, { target: grow, prop: "xScale", from: m.s0, to: 1, span: ms(m.p) });
                break;
            case "ripple": {
                const ph = ((m.d * m.n) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
                hideBelow = m.min;
                grow.xScale = 0.5 + 0.5 * Math.cos(ph);
                scene.cosine.createObject(nd, { target: grow, phase: ph, period: ms(2 * Math.PI / m.w) });
                break;
            }
            }
        }
    }

    Rectangle {
        visible: nd.kind === "dot"
        x: nd.kind === "dot" ? nd.n.x - nd.n.rad : 0
        y: nd.kind === "dot" ? nd.n.y - nd.n.rad : 0
        width: nd.kind === "dot" ? nd.n.rad * 2 : 0
        height: width
        radius: width / 2
        antialiasing: true
        color: nd.kind === "dot" ? nd.n.f : "transparent"
    }

    Repeater {
        model: nd.kind === "node" ? nd.n.p : []
        Shape {
            required property var modelData
            preferredRendererType: Shape.CurveRenderer
            opacity: modelData.op ?? 1
            ShapePath {
                fillColor: modelData.f ?? "transparent"
                fillRule: ShapePath.WindingFill
                strokeColor: modelData.s ?? "transparent"
                strokeWidth: modelData.s ? modelData.w : -1
                capStyle: modelData.cap === "butt" ? ShapePath.FlatCap : ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathSvg { path: modelData.d }
            }
        }
    }

    Loader {
        active: nd.kind === "group"
        sourceComponent: Item {
            Component.onCompleted: {
                const list = [];
                for (const t of nd.n.g.slice().reverse()) {
                    if (t[0] === "translate") list.push(Qt.createQmlObject(`import QtQuick; Translate { x: ${t[1]}; y: ${t[2]} }`, this));
                    else if (t[0] === "scale") list.push(Qt.createQmlObject(`import QtQuick; Scale { xScale: ${t[1]}; yScale: ${t[1]} }`, this));
                    else list.push(Qt.createQmlObject(`import QtQuick; Rotation { angle: ${t[1]}; origin.x: ${t[2]}; origin.y: ${t[3]} }`, this));
                }
                transform = list;
            }
            Repeater {
                model: nd.n.c
                Loader {
                    required property var modelData
                    source: "SceneNode.qml"
                    onLoaded: { item.scene = nd.scene; item.n = modelData; }
                }
            }
        }
    }
}

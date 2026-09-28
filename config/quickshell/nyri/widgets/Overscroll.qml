import QtQuick

Item {
    id: root

    required property Flickable flick
    property real step: 1.5
    property real touchpad: 1.7

    property real speed: 0
    property real lastAt: 0

    width: 0
    height: 0

    readonly property real minY: flick.originY - flick.topMargin
    readonly property real maxY: Math.max(minY, flick.originY + flick.contentHeight + flick.bottomMargin - flick.height)

    SpringValue { id: kick; target: 0; damping: 0.55; stiffness: 520; epsilon: 0.2 }
    readonly property real o: flick.verticalOvershoot !== 0 ? flick.verticalOvershoot : kick.value
    readonly property real k: Math.min(0.14, Math.abs(o) / Math.max(1, flick.height) * 0.7)

    Scale {
        id: stretch
        origin.x: root.flick.width / 2
        origin.y: root.o < 0 ? root.flick.contentY : root.flick.contentY + root.flick.height
        yScale: 1 + root.k
        xScale: 1 - root.k * 0.12
    }

    property real goal: 0
    SpringValue {
        id: glide
        damping: 1.0
        stiffness: 380
        epsilon: 0.3
        onValueChanged: if (running) root.flick.contentY = value
    }

    WheelHandler {
        parent: root.flick
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const f = root.flick;
            const pad = event.device.type === PointerDevice.TouchPad || (event.pixelDelta.y !== 0 && Math.abs(event.angleDelta.y) < 120);
            if (pad) {
                glide.running = false;
                const now = Date.now();
                if (event.phase === Qt.ScrollBegin) { root.speed = 0; f.cancelFlick(); }
                if (event.phase === Qt.ScrollEnd) {
                    if (Math.abs(root.speed) > 150 && now - root.lastAt < 120) f.flick(0, -root.speed);
                    root.speed = 0;
                    return;
                }
                if (event.phase === Qt.ScrollMomentum) return;
                const d = -(event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 8) * root.touchpad;
                const dt = Math.max(4, Math.min(100, now - root.lastAt));
                root.speed = root.speed * 0.6 + (d / dt * 1000) * 0.4;
                root.lastAt = now;
                const want = f.contentY + d;
                const clamped = Math.max(root.minY, Math.min(root.maxY, want));
                if (clamped !== want && Math.abs(want - clamped) > 2 && !kick.running) {
                    kick.velocity = (want < clamped ? -1 : 1) * Math.min(1200, Math.abs(root.speed) * 0.5 + 300);
                    kick.running = true;
                }
                f.contentY = clamped;
                return;
            }
            if (!glide.running) { glide.value = f.contentY; glide.velocity = 0; root.goal = f.contentY; }
            const want = root.goal - event.angleDelta.y * root.step;
            const clamped = Math.max(root.minY, Math.min(root.maxY, want));
            if (clamped !== want && Math.abs(root.goal - clamped) < 1) {
                kick.velocity = (want < clamped ? -1 : 1) * 900;
                kick.running = true;
            }
            root.goal = clamped;
            glide.target = clamped;
            glide.running = true;
        }
    }

    Connections {
        target: root.flick
        function onMovementStarted() { glide.running = false; }
    }

    Component.onCompleted: {
        flick.flickDeceleration = 2200;
        flick.maximumFlickVelocity = 9000;
        flick.boundsBehavior = Flickable.DragAndOvershootBounds;
        flick.boundsMovement = Flickable.StopAtBounds;
        flick.contentItem.transform = [stretch];
    }
}

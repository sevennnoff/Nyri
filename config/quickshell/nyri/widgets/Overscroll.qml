import QtQuick

Item {
    id: root

    required property Flickable flick
    property real step: 1.5

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
            if (event.pixelDelta.y !== 0 && event.device.type === PointerDevice.TouchPad) {
                glide.running = false;
                f.contentY = Math.max(root.minY, Math.min(root.maxY, f.contentY - event.pixelDelta.y));
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
        flick.boundsBehavior = Flickable.DragAndOvershootBounds;
        flick.boundsMovement = Flickable.StopAtBounds;
        flick.contentItem.transform = [stretch];
    }
}

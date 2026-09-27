import QtQuick
import qs.theme

// A number that follows `target` like a damped spring (unit mass), integrated
// every frame — so it runs at the display's refresh rate, and when the target
// changes mid-flight it keeps its velocity and bends toward the new target
// instead of restarting. That is what makes interrupted motion flow.
//
// Idle when settled: the FrameAnimation stops, nothing ticks.
FrameAnimation {
    id: root

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real damping: 0.7
    property real stiffness: 420
    property real epsilon: 0.0005

    onTargetChanged: running = true
    Component.onCompleted: value = target

    onTriggered: {
        const dt = Math.min(frameTime, 0.05);
        const steps = Math.max(1, Math.ceil(dt / 0.004));
        const h = dt / steps;
        const k = stiffness * Motion.speed * Motion.speed;
        const c = 2 * damping * Math.sqrt(k);
        let x = value, v = velocity;
        for (let i = 0; i < steps; i++) {
            v += (-k * (x - target) - c * v) * h;
            x += v * h;
        }
        if (Math.abs(x - target) < epsilon && Math.abs(v) < epsilon * 20) {
            x = target;
            v = 0;
            running = false;
        }
        velocity = v;
        value = x;
    }
}

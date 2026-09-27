import QtQuick
import qs.theme

// Position / size / shape. Overshoots, like a spring.
NumberAnimation {
    property string speed: "default"   // fast | default | slow
    readonly property var token: speed === "fast" ? Motion.fastSpatial
                               : speed === "slow" ? Motion.slowSpatial
                               : Motion.defaultSpatial
    duration: token.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: token.curve
}

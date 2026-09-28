import QtQuick
import qs.theme

NumberAnimation {
    property string speed: "default"
    readonly property var token: speed === "fast" ? Motion.fastSpatial
                               : speed === "slow" ? Motion.slowSpatial
                               : Motion.defaultSpatial
    duration: token.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: token.curve
}

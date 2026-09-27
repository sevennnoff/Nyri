import QtQuick
import qs.theme

ColorAnimation {
    duration: Motion.effects.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.effects.curve
}

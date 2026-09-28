import QtQuick
import qs.theme

NumberAnimation {
    duration: Motion.effects.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.effects.curve
}

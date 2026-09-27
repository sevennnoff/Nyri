import QtQuick
import qs.theme

// Opacity and other non-spatial numbers. Never overshoots.
NumberAnimation {
    duration: Motion.effects.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.effects.curve
}

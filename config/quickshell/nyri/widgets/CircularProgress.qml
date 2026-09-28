import QtQuick
import QtQuick.Shapes as Vec
import qs.theme

Item {
    id: root

    property real value: 0
    property real stroke: 8
    property color activeColor: Colors.m3primary
    property color trackColor: Colors.m3secondaryContainer

    property bool animated: true

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown {
        enabled: root.animated
        NumberAnimation {
            duration: 900
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.emphasizedDecel.curve
        }
    }

    readonly property real r: Math.max(1, Math.min(width, height) / 2 - stroke / 2)
    readonly property real gapDeg: shown > 0.001 && shown < 0.999 ? (stroke * 1.4) / r * 180 / Math.PI : 0
    readonly property real sweep: shown * 360

    Vec.Shape {
        anchors.fill: parent
        preferredRendererType: Vec.Shape.CurveRenderer

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.stroke
            capStyle: Vec.ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: -90 + root.sweep + root.gapDeg
                sweepAngle: Math.max(0.01, 360 - root.sweep - 2 * root.gapDeg)
            }
        }

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: root.shown > 0.001 ? root.activeColor : "transparent"
            strokeWidth: root.stroke
            capStyle: Vec.ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: -90
                sweepAngle: Math.max(0.01, root.sweep)
            }
        }
    }
}

import QtQuick
import qs.theme

Row {
    id: root

    property real level: 0
    property bool charging: false
    property real size: 14
    property int textSize: Math.round(size * 0.95)
    property int textWeight: 700
    property bool showText: true
    property color color: Colors.m3onSurfaceVariant

    readonly property bool low: level <= 0.15 && !charging
    readonly property color ink: low ? Colors.m3error : root.color
    readonly property color fillColor: low ? Colors.m3error : Colors.m3primary
    readonly property real stroke: Math.max(1.5, Math.round(size * 0.085 * 2) / 2)
    readonly property real gap: Math.max(1, Math.round(size * 0.06 * 2) / 2)

    spacing: Math.round(size * 0.35)

    Item {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        width: body.width + nub.width + root.stroke * 0.5
        height: root.size

        Rectangle {
            id: body
            width: Math.round(root.size * 1.9)
            height: root.size
            radius: Math.min(height / 2, root.size * 0.32)
            color: "transparent"
            border.width: root.stroke
            border.color: Qt.alpha(root.ink, 0.55)
            Behavior on border.color { ColorAnim {} }

            SpringValue { id: fillS; target: root.level; damping: 0.85; stiffness: 220; epsilon: 0.0005 }
            readonly property real inner: root.stroke + root.gap

            Rectangle {
                id: fill
                x: body.inner
                y: body.inner
                height: body.height - 2 * body.inner
                width: Math.max(height * 0.5, (body.width - 2 * body.inner) * Math.max(0, Math.min(1, fillS.value)))
                radius: Math.max(1, body.radius - body.inner)
                color: root.fillColor
                clip: true
                Behavior on color { ColorAnim {} }

                Rectangle {
                    id: glint
                    visible: root.charging
                    width: fill.height * 3
                    height: fill.height
                    x: -width
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.alpha(Colors.m3onPrimary, 0) }
                        GradientStop { position: 0.5; color: Qt.alpha(Colors.m3onPrimary, 0.45) }
                        GradientStop { position: 1.0; color: Qt.alpha(Colors.m3onPrimary, 0) }
                    }
                    SequentialAnimation on x {
                        running: root.charging && root.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: -glint.width; to: fill.width; duration: 1300; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 1700 }
                    }
                }
            }
        }

        Rectangle {
            id: nub
            anchors.left: body.right
            anchors.leftMargin: root.stroke * 0.5
            anchors.verticalCenter: body.verticalCenter
            width: Math.max(1.5, root.size * 0.14)
            height: root.size * 0.42
            radius: width / 2
            color: Qt.alpha(root.ink, 0.55)
        }
    }

    Row {
        visible: root.showText
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Reveal {
            shown: root.charging
            MIcon {
                icon: "bolt"
                size: Math.round(root.textSize * 1.1)
                fill: 1
                color: Colors.m3primary
            }
        }
        RollingText {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.textSize
            weight: root.textWeight
            color: root.low ? Colors.m3error : Colors.m3onSurface
            text: Math.round(root.level * 100) + "%"
        }
    }
}

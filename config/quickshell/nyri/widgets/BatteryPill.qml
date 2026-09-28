import QtQuick
import qs.theme

Item {
    id: root

    property real level: 0
    property bool charging: false
    property int textSize: 12
    property int textWeight: 800
    property color color: Colors.m3surfaceContainerHighest

    readonly property bool low: level <= 0.15 && !charging
    readonly property color fillColor: low ? Colors.m3error : Colors.m3primary
    readonly property color onFill: low ? Colors.m3onError : Colors.m3onPrimary
    readonly property string label: Math.round(level * 100) + (textSize > 20 ? "%" : "")
    readonly property real nubW: Math.max(2, Math.round(height * 0.14))
    readonly property real inset: Math.max(2, Math.round(height * 0.12))
    readonly property real bodyW: width - nubW - 1

    Rectangle {
        x: root.bodyW + 1
        anchors.verticalCenter: parent.verticalCenter
        width: root.nubW
        height: root.height * 0.42
        radius: width
        color: root.level >= 0.99 ? root.fillColor : root.color
        Behavior on color { ColorAnim {} }
    }

    Rectangle {
        id: body
        width: root.bodyW
        height: root.height
        radius: height / 2
        color: root.color
        clip: true

        SpringValue { id: fillS; target: root.level; damping: 0.8; stiffness: 260; epsilon: 0.0005 }
        readonly property real fillW: Math.max(height - 2 * root.inset, (width - 2 * root.inset) * Math.max(0, Math.min(1, fillS.value)))
        readonly property bool onTop: root.level >= 0.5

        Rectangle {
            id: fill
            x: root.inset
            y: root.inset
            width: body.fillW
            height: body.height - 2 * root.inset
            radius: height / 2
            color: root.fillColor
            clip: true
            Behavior on color { ColorAnim {} }

            Rectangle {
                id: glint
                visible: root.charging
                width: fill.height * 2
                height: fill.height
                x: -width
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.alpha(root.onFill, 0) }
                    GradientStop { position: 0.5; color: Qt.alpha(root.onFill, 0.35) }
                    GradientStop { position: 1.0; color: Qt.alpha(root.onFill, 0) }
                }
                SequentialAnimation on x {
                    running: root.charging && root.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: -glint.width; to: fill.width; duration: 1400; easing.type: Easing.InOutQuad }
                    PauseAnimation { duration: 1600 }
                }
            }
        }

        Row {
            id: label
            spacing: 0
            readonly property real onFillX: fill.x + (fill.width - width) / 2
            readonly property real emptyX: fill.x + fill.width + (body.width - root.inset - fill.x - fill.width - width) / 2
            SpringValue { id: tx; target: body.onTop ? label.onFillX : label.emptyX; damping: 0.7; stiffness: 520; epsilon: 0.1 }
            x: Math.max(root.inset, Math.min(body.width - root.inset - width, tx.value))
            anchors.verticalCenter: parent.verticalCenter
            readonly property color ink: body.onTop ? root.onFill : Colors.m3onSurface

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.charging
                icon: "bolt"
                size: Math.round(root.textSize * 1.15)
                fill: 1
                color: label.ink
            }
            MText {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: root.textSize
                font.variableAxes: ({ "wght": root.textWeight })
                font.features: { "tnum": 1 }
                color: label.ink
                Behavior on color { ColorAnim {} }
                text: root.label
            }
        }
    }
}

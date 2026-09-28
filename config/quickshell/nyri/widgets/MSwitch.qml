import QtQuick
import qs.theme

Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32

    SpringValue {
        id: pos
        target: root.checked ? 1 : 0
        damping: 0.55
        stiffness: 650
    }

    SpringValue {
        id: press
        target: mouse.pressed ? 1 : 0
        damping: 0.8
        stiffness: 900
    }

    readonly property real t: Math.max(0, Math.min(1, pos.value))

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colors.m3primary : Colors.m3surfaceContainerHighest
        border.width: 2 * (1 - root.t)
        border.color: Colors.m3outline

        Behavior on color { ColorAnim {} }
    }

    Rectangle {
        readonly property real rest: 16 + 8 * root.t
        readonly property real size: rest + (28 - rest) * press.value
        readonly property real stretch: Math.min(7, Math.abs(pos.velocity) * 0.7)
        readonly property real cx: root.height / 2 + pos.value * (root.width - root.height)

        width: size + stretch
        height: size - stretch * 0.15
        radius: height / 2
        x: cx - width / 2
        y: (root.height - height) / 2
        color: root.checked ? Colors.m3onPrimary : Colors.m3outline

        Behavior on color { ColorAnim {} }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -8
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}

import QtQuick
import qs.theme

Item {
    id: root

    property bool checked: false
    implicitWidth: 20
    implicitHeight: 20

    SpringValue { id: dot; target: root.checked ? 1 : 0; damping: 0.5; stiffness: 800; epsilon: 0.001 }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.checked ? Colors.m3primary : Colors.m3onSurfaceVariant

        Behavior on border.color { ColorAnim {} }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 10 * dot.value
        height: width
        radius: width / 2
        color: Colors.m3primary
    }
}

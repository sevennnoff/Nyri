import QtQuick
import qs.theme

Item {
    id: root

    property bool shown: true
    default property alias content: holder.data
    readonly property Item item: holder.children.length ? holder.children[0] : null

    SpringValue { id: p; target: root.shown ? 1 : 0; damping: 0.66; stiffness: 520; epsilon: 0.002 }
    readonly property real v: Math.max(0, p.value)

    implicitWidth: (item?.implicitWidth ?? 0) * v
    implicitHeight: item?.implicitHeight ?? 0
    visible: v > 0.01
    anchors.verticalCenter: parent?.verticalCenter

    Item {
        id: holder
        anchors.centerIn: parent
        width: root.item?.implicitWidth ?? 0
        height: root.implicitHeight
        opacity: Math.max(0, Math.min(1, root.v * 1.6 - 0.5))
        scale: 0.5 + 0.5 * Math.min(1, root.v)
    }
}

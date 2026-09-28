import QtQuick
import qs.theme

Item {
    id: root

    property bool shown: true
    default property alias content: holder.data
    readonly property Item item: holder.children.length ? holder.children[0] : null

    SpringValue { id: p; target: root.shown ? 1 : 0; damping: 0.72; stiffness: 380; epsilon: 0.002 }
    Component.onCompleted: { p.value = shown ? 1 : 0; }
    readonly property real v: Math.max(0, p.value)

    implicitWidth: item?.implicitWidth ?? 0
    implicitHeight: (item?.height ?? 0) * v
    height: implicitHeight
    visible: v > 0.01
    clip: p.running

    Item {
        id: holder
        width: root.width
        height: root.item?.height ?? 0
        opacity: Math.max(0, Math.min(1, root.v * 1.6 - 0.5))
        scale: 0.94 + 0.06 * Math.min(1, root.v)
        transformOrigin: Item.Top
    }
}

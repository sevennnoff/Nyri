import QtQuick
import qs.theme

Item {
    id: root

    default property alias content: holder.data
    readonly property Item card: holder.children.length ? holder.children[0] : null
    property bool swipeEnabled: true
    signal dismissed

    implicitHeight: (card?.height ?? 0) * collapse.value
    clip: collapse.value < 0.999

    property bool gone: false
    property int side: 1
    readonly property real t: drag.active ? drag.activeTranslation.x : 0
    readonly property real pulled: Math.sign(t) * width * 0.9 * (1 - Math.exp(-Math.abs(t) / (width * 0.9)))

    SpringValue {
        id: sx
        target: root.gone ? root.side * root.width * 1.3 : drag.active ? root.pulled : 0
        damping: root.gone ? 1 : drag.active ? 0.95 : 0.6
        stiffness: drag.active ? 2200 : root.gone ? 320 : 420
        epsilon: 0.2
        onRunningChanged: if (!running && root.gone) collapse.target = 0
    }
    SpringValue {
        id: collapse
        target: 1
        damping: 0.9
        stiffness: 380
        epsilon: 0.002
        onRunningChanged: if (!running && target === 0) root.dismissed()
    }
    Component.onCompleted: { collapse.value = 0; collapse.running = true; }

    readonly property real v: Math.max(-1, Math.min(1, sx.velocity / 3000))

    Item {
        id: holder
        width: parent.width
        height: root.card?.height ?? 0
        x: sx.value
        opacity: 1 - Math.min(1, Math.abs(sx.value) / (root.width * 1.2))
        rotation: sx.value / Math.max(1, root.width) * 7
        transform: Scale {
            origin.x: holder.width / 2
            origin.y: holder.height / 2
            xScale: 1 + Math.abs(root.v) * 0.06
            yScale: 1 - Math.abs(root.v) * 0.05
        }
    }

    DragHandler {
        id: drag
        target: null
        enabled: root.swipeEnabled && !root.gone
        yAxis.enabled: false
        onActiveChanged: {
            if (active) return;
            const far = Math.abs(sx.value) > root.width * 0.33;
            const flung = Math.abs(sx.velocity) > 1400;
            if (far || flung) {
                root.side = sx.value !== 0 ? Math.sign(sx.value) : Math.sign(sx.velocity) || 1;
                root.gone = true;
            }
        }
    }
}

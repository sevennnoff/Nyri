import QtQuick
import qs.theme
import qs.services

Card {
    id: root

    required property real progress
    default property alias content: inner.data

    property real toX
    property real toY: 12 + 40 + 12
    property real toW
    property real toH

    property real defaultFromX: toX + toW / 2 - 60
    property real defaultFromW: 120
    readonly property bool fromBar: Panels.anchorW > 0
    readonly property real fromX: fromBar ? Panels.anchorX : defaultFromX
    readonly property real fromW: fromBar ? Panels.anchorW : defaultFromW
    readonly property real fromY: 12
    readonly property real fromH: 40

    readonly property real p: Math.max(0, progress)
    readonly property real pc: Math.min(1, p)

    x: fromX + (toX - fromX) * p
    y: fromY + (toY - fromY) * p
    width: Math.max(0, fromW + (toW - fromW) * p)
    height: Math.max(0, fromH + (toH - fromH) * p)
    radius: fromH / 2 + (Shape.extraLarge - fromH / 2) * pc
    color: Colors.m3surfaceContainer
    elevation: 3
    opacity: Math.min(1, p * 4)
    clip: true

    function stage(i) {
        return Math.max(0, Math.min(1, (p - 0.3 - i * 0.06) / 0.4));
    }

    Item {
        id: inner
        width: root.toW
        height: root.toH

        Component.onCompleted: Qt.callLater(root.cascade)
    }

    function cascade() {
        const column = inner.children[0];
        if (!column)
            return;
        const target = column.children && column.children.length > 1 ? column : inner;
        for (let i = 0; i < target.children.length; i++) {
            const item = target.children[i];
            const index = i;
            item.opacity = Qt.binding(() => root.stage(index));
            const shift = Qt.createQmlObject("import QtQuick; Translate {}", item);
            shift.y = Qt.binding(() => (1 - root.stage(index)) * 18);
            item.transform = [shift];
        }
    }
}

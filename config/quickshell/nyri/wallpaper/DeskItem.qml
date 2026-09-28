import QtQuick
import qs.theme
import qs.services
import qs.widgets

Item {
    id: root

    required property string key
    required property Item desk
    property real defaultX: 56
    property real defaultY: 112
    default property alias body: holder.data
    readonly property Item child: holder.children.length ? holder.children[0] : null

    readonly property var saved: Config.o.desktop.positions?.[key] ?? null

    property string title: ""
    property var variantNames: []
    property var looks: []
    readonly property int variantCount: Math.max(1, variantNames.length)
    readonly property int variant: (Config.o.desktop.variants?.[key] ?? 0) % variantCount
    signal menuRequested
    function setVariant(i) {
        if (i === variant) return;
        const v = Object.assign({}, Config.o.desktop.variants ?? {});
        v[key] = i;
        Config.o.desktop.variants = v;
        swapS.value = 0;
        swapS.running = true;
    }
    SpringValue { id: swapS; target: 1; damping: 0.5; stiffness: 420 }
    readonly property real homeX: clampX(saved ? saved.x : defaultX)
    readonly property real homeY: clampY(saved ? saved.y : defaultY)
    readonly property bool dragging: drag.active || fake.active

    QtObject {
        id: fake
        property bool active: false
        property real x: 0
        property real y: 0
        property real offX: 0
        property real offY: 0
        onXChanged: if (active && Demo.holding) Demo.x = x + root.desk.shiftX + offX
        onYChanged: if (active && Demo.holding) Demo.y = y + root.desk.shiftY + offY
    }
    function demoDrag(toX, toY) {
        fake.x = homeX;
        fake.y = homeY;
        fake.offX = Demo.x - (homeX + desk.shiftX);
        fake.offY = Demo.y - (homeY + desk.shiftY);
        Demo.holding = true;
        fake.active = true;
        fakeMove.toX = toX;
        fakeMove.toY = toY;
        fakeMove.restart();
    }
    SequentialAnimation {
        id: fakeMove
        property real toX: 0
        property real toY: 0
        PauseAnimation { duration: 350 }
        ParallelAnimation {
            NumberAnimation { target: fake; property: "x"; to: fakeMove.toX; duration: 1500; easing.type: Easing.InOutCubic }
            NumberAnimation { target: fake; property: "y"; to: fakeMove.toY; duration: 1500; easing.type: Easing.InOutCubic }
        }
        PauseAnimation { duration: 400 }
        ScriptAction { script: root.drop() }
    }
    readonly property real heldX: fake.active ? fake.x : homeX + drag.activeTranslation.x
    readonly property real heldY: fake.active ? fake.y : homeY + drag.activeTranslation.y
    function drop() {
        const p = Object.assign({}, Config.o.desktop.positions ?? {});
        p[root.key] = { x: root.dropX, y: root.dropY };
        fake.active = false;
        Demo.holding = false;
        Config.o.desktop.positions = p;
    }

    readonly property real dropX: clampX(snap(heldX))
    readonly property real dropY: clampY(snap(heldY))

    function snap(v) {
        const g = Config.o.desktop.gridSize;
        return Config.o.desktop.grid && g > 0 ? Math.round(v / g) * g : v;
    }
    function clampX(v) { return Math.max(0, Math.min(desk.width - width, v)); }
    function clampY(v) { return Math.max(56, Math.min(desk.height - height, v)); }

    property bool shown: true
    width: shown ? child?.width ?? 0 : 0
    height: shown ? child?.height ?? 0 : 0
    visible: shown

    SpringValue { id: sx; target: root.dragging ? root.heldX : root.homeX; damping: 0.62; stiffness: root.dragging ? 2400 : 300; epsilon: 0.1 }
    SpringValue { id: sy; target: root.dragging ? root.heldY : root.homeY; damping: 0.62; stiffness: root.dragging ? 2400 : 300; epsilon: 0.1 }
    x: sx.value + desk.shiftX
    y: sy.value + desk.shiftY
    z: dragging ? 10 : 0

    SpringValue { id: lift; target: root.dragging ? 1 : 0; damping: 0.6; stiffness: 500 }
    scale: (1 + 0.04 * lift.value) * (0.9 + 0.1 * swapS.value)
    opacity: Math.min(1, 0.3 + 0.7 * swapS.value)

    DragHandler {
        id: drag
        target: null
        onActiveChanged: if (!active) root.drop()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.menuRequested()
    }

    HoverHandler { cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor }

    Rectangle {
        anchors.fill: holder
        anchors.margins: -2
        radius: Math.min(height / 2, Shape.extraLarge)
        color: "transparent"
        border.width: 2
        border.color: Colors.m3primary
        opacity: 0.6 * lift.value
    }

    Item {
        id: holder
        anchors.fill: parent
    }
}

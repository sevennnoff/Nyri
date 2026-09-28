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

    readonly property string placeKey: desk.output + "/" + key
    readonly property var saved: Config.o.desktop.positions?.[placeKey] ?? Config.o.desktop.positions?.[key] ?? null

    readonly property var only: Config.o.desktop.only?.[key] ?? null
    readonly property bool here: !only || ((!only.output || only.output === desk.output) && (!only.ws || only.ws === desk.wsIdx))
    function pinHere(what) {
        const o = Object.assign({}, Config.o.desktop.only ?? {});
        const cur = Object.assign({}, o[key] ?? {});
        if (what === "ws") cur.ws = cur.ws ? 0 : desk.wsIdx;
        if (what === "output") cur.output = cur.output ? "" : desk.output;
        if (what === "ws" && cur.ws) cur.output = desk.output;
        if (!cur.ws && !cur.output) delete o[key]; else o[key] = cur;
        Config.o.desktop.only = o;
    }

    readonly property real savedScale: Config.o.desktop.scales?.[key] ?? 1
    property real liveScale: 0
    readonly property real kk: liveScale > 0 ? liveScale : savedScale
    SpringValue { id: kS; target: root.kk; damping: 0.7; stiffness: 520; epsilon: 0.001 }

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
        p[root.placeKey] = { x: root.dropX, y: root.dropY };
        fake.active = false;
        Demo.holding = false;
        Config.o.desktop.positions = p;
    }

    readonly property point landing: dragging ? desk.freeSpot(root, clampX(snap(heldX)), clampY(snap(heldY))) : Qt.point(homeX, homeY)
    readonly property real dropX: landing.x
    readonly property real dropY: landing.y

    function snap(v) {
        const g = Config.o.desktop.gridSize;
        return Config.o.desktop.grid && g > 0 ? Math.round(v / g) * g : v;
    }
    function clampX(v) { return Math.max(0, Math.min(desk.width - width, v)); }
    function clampY(v) {
        const top = Panels.barBottom ? 12 : 56, bottom = Panels.barBottom ? 56 : 0;
        return Math.max(top, Math.min(desk.height - height - bottom, v));
    }

    property bool shown: true
    readonly property bool on: shown && here
    width: on ? (child?.width ?? 0) * kS.value : 0
    height: on ? (child?.height ?? 0) * kS.value : 0
    visible: on

    readonly property point push: {
        const h = desk.held;
        if (!h || h === root || !on) return Qt.point(0, 0);
        const ox = Math.min(h.dropX + h.width, homeX + width) - Math.max(h.dropX, homeX);
        const oy = Math.min(h.dropY + h.height, homeY + height) - Math.max(h.dropY, homeY);
        if (ox <= 0 || oy <= 0) return Qt.point(0, 0);
        const dx = (homeX + width / 2) - (h.dropX + h.width / 2);
        const dy = (homeY + height / 2) - (h.dropY + h.height / 2);
        if (ox < oy) return Qt.point(Math.sign(dx || 1) * Math.min(56, ox + 12), 0);
        return Qt.point(0, Math.sign(dy || 1) * Math.min(56, oy + 12));
    }

    SpringValue { id: sx; target: root.dragging ? root.heldX : root.homeX + root.push.x; damping: 0.62; stiffness: root.dragging ? 2400 : 300; epsilon: 0.1 }
    SpringValue { id: sy; target: root.dragging ? root.heldY : root.homeY + root.push.y; damping: 0.62; stiffness: root.dragging ? 2400 : 300; epsilon: 0.1 }
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
        anchors.fill: parent
        anchors.margins: -8
        radius: Math.min(height / 2, Shape.extraLarge + 8)
        color: root.desk.editing ? Qt.alpha(Colors.m3primary, 0.06) : "transparent"
        border.width: 2
        border.color: Colors.m3primary
        opacity: Math.max(0.6 * lift.value, root.desk.editing ? 0.85 : 0)
    }

    Item {
        id: holder
        width: root.child?.width ?? 0
        height: root.child?.height ?? 0
        scale: kS.value
        transformOrigin: Item.TopLeft
    }

    MouseArea {
        anchors.fill: parent
        visible: root.desk.editing
        acceptedButtons: Qt.LeftButton
    }
    Item {
        anchors.fill: parent
        visible: root.desk.editing
        z: 20
        SpringValue { id: editIn; target: root.desk.editing ? 1 : 0; damping: 0.6; stiffness: 520 }

        Rectangle {
            x: -12
            y: -12
            width: 32
            height: 32
            radius: 16
            scale: editIn.value
            color: Colors.m3errorContainer
            MIcon { anchors.centerIn: parent; icon: "close"; size: 18; color: Colors.m3onErrorContainer }
            StateLayer { radius: 16; color: Colors.m3onErrorContainer; onClicked: Config.o.desktop[root.key] = false }
        }

        Rectangle {
            id: grip
            x: parent.width - 20
            y: parent.height - 20
            width: 36
            height: 36
            radius: 18
            scale: editIn.value * (gripDrag.active ? 1.15 : 1)
            color: Colors.m3primary
            MIcon { anchors.centerIn: parent; icon: "open_in_full"; size: 18; color: Colors.m3onPrimary; rotation: 90 }
            HoverHandler { cursorShape: Qt.SizeFDiagCursor }
            property real startK: 1
            DragHandler {
                id: gripDrag
                target: null
                onActiveChanged: {
                    if (active) { grip.startK = root.savedScale; return; }
                    const s = Object.assign({}, Config.o.desktop.scales ?? {});
                    s[root.key] = root.liveScale > 0 ? root.liveScale : root.savedScale;
                    Config.o.desktop.scales = s;
                    root.liveScale = 0;
                }
                onTranslationChanged: {
                    if (!active) return;
                    const base = (root.child?.width ?? 1) + (root.child?.height ?? 1);
                    const k = grip.startK * (1 + (translation.x + translation.y) / base);
                    root.liveScale = Math.max(0.5, Math.min(2, Math.round(k * 20) / 20));
                }
            }
        }

        Rectangle {
            visible: gripDrag.active
            anchors.centerIn: parent
            width: kText.implicitWidth + 24
            height: 32
            radius: 16
            color: Colors.m3inverseSurface
            MText { id: kText; anchors.centerIn: parent; textStyle: Type.labelLargeEmph; color: Colors.m3inverseOnSurface; text: Math.round(root.kk * 100) + "%" }
        }
    }
}

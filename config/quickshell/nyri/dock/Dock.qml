import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Variants {
    model: Config.o.dock.enabled ? Quickshell.screens : []

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var cfg: Config.o.dock
        readonly property real sz: cfg.size
        readonly property real pad: 10
        readonly property real dockH: sz + 2 * pad
        readonly property real lift: Panels.barBottom ? Panels.barReach + 8 : 0

        screen: modelData
        anchors { bottom: true; left: true; right: true }
        implicitHeight: dockH + 12 + lift + Math.max(sz * 0.6 + 140, menuCard.height + 24)
        color: "transparent"
        exclusionMode: cfg.autohide ? ExclusionMode.Ignore : ExclusionMode.Normal
        exclusiveZone: cfg.autohide ? 0 : dockH + 12 + lift
        WlrLayershell.namespace: "nyri-dock"
        WlrLayershell.layer: cfg.autohide ? WlrLayer.Overlay : WlrLayer.Top

        function keyOf(appId) { return DesktopEntries.heuristicLookup(appId)?.id ?? appId; }
        readonly property var pinned: Array.isArray(cfg.pinned) ? cfg.pinned : []
        readonly property var items: {
            const byKey = {};
            const order = [];
            for (const id of pinned) {
                const e = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
                if (!e && !id) continue;
                byKey[id] = { key: id, entry: e, appId: id, windows: [], pinned: true };
                order.push(id);
            }
            if (cfg.running) {
                const ws = Object.values(Niri.windows).sort((a, b) => (b.focus_timestamp?.secs ?? 0) - (a.focus_timestamp?.secs ?? 0));
                for (const w of ws) {
                    if (!w.app_id || w.app_id === "org.quickshell") continue;
                    const k = keyOf(w.app_id);
                    if (!byKey[k]) {
                        byKey[k] = { key: k, entry: DesktopEntries.heuristicLookup(w.app_id), appId: w.app_id, windows: [], pinned: false };
                        order.push(k);
                    }
                    byKey[k].windows.push(w);
                    byKey[k].appId = w.app_id;
                }
            }
            return order.map(k => byKey[k]);
        }
        readonly property string focusedKey: Niri.focusedWindow ? keyOf(Niri.focusedWindow.app_id) : ""

        function activate(it) {
            if (!it.windows.length) {
                if (it.entry) Apps.launch(it.entry);
                return true;
            }
            const focused = it.windows.findIndex(w => w.is_focused);
            const next = it.windows[focused >= 0 ? (focused + 1) % it.windows.length : 0];
            Niri.action("focus-window", "--id", String(next.id));
            return false;
        }
        function setPinned(list) { Config.o.dock.pinned = list; }

        Timer {
            running: !win.cfg.seeded && Object.keys(Apps.counts).length > 0
            interval: 1500
            onTriggered: {
                if (win.cfg.seeded) return;
                win.setPinned(Apps.search("").slice(0, 5).map(e => e.id));
                Config.o.dock.seeded = true;
            }
        }
        function togglePin(it) {
            if (it.pinned) setPinned(pinned.filter(k => k !== it.key));
            else setPinned(pinned.concat([it.key]));
        }
        function closeAll(it) { for (const w of it.windows) Niri.action("close-window", "--id", String(w.id)); }

        readonly property bool emptyDesk: {
            const ws = Niri.workspaces.find(w => w.output === modelData.name && w.is_active);
            return !ws || Niri.windowCount(ws.id) === 0;
        }
        property bool pointerIn: false
        readonly property bool revealed: !Panels.deskEdit && items.length > 0 && (!cfg.autohide || pointerIn || emptyDesk || menu.item !== null || drag.key !== "")
        SpringValue { id: reveal; target: win.revealed ? 1 : 0; damping: win.revealed ? 0.62 : 1; stiffness: win.revealed ? 420 : 380 }

        mask: Region {
            Region { item: reveal.value > 0.5 ? hitDock : edge }
            Region { item: menu.item ? menuCard : null }
            Region { item: drag.key !== "" ? all : null }
        }
        Item { id: all; anchors.fill: parent }
        Item { id: edge; width: parent.width; height: 3; y: parent.height - 3 - win.lift }
        Item { id: hitDock; x: dock.x - 8; y: dock.y - win.sz * 0.6; width: dock.width + 16; height: win.height - y - win.lift }

        HoverHandler {
            onHoveredChanged: { if (hovered) { leave.stop(); win.pointerIn = true; } else leave.restart(); }
        }
        Timer { id: leave; interval: 500; onTriggered: win.pointerIn = false }

        property real mouseX: -1e6
        HoverHandler {
            id: over
            target: dock
            onPointChanged: win.mouseX = point.position.x
            onHoveredChanged: if (!hovered) win.mouseX = -1e6
        }
        function swell(cx) {
            if (!cfg.magnify || drag.key !== "") return 1;
            const d = (cx - mouseX) / (sz * 1.5);
            return 1 + 0.5 * Math.exp(-d * d);
        }

        QtObject {
            id: drag
            property string key: ""
            property real x: 0
            property real y: 0
            property int to: -1
            readonly property bool away: key !== "" && y < -win.sz * 1.2
        }

        Item {
            id: dock
            readonly property var slots: {
                const out = {};
                let x = win.pad;
                let i = 0;
                for (const it of win.items) {
                    if (it.key === drag.key) continue;
                    if (drag.key !== "" && !drag.away && i === drag.to) x += win.sz + 8;
                    out[it.key] = x + win.sz / 2;
                    x += win.sz + 8;
                    i++;
                }
                return { at: out, width: Math.max(win.sz, x - 8 + win.pad + (drag.key !== "" && !drag.away && drag.to >= i ? win.sz + 8 : 0)) };
            }
            SpringValue { id: dockW; target: dock.slots.width; damping: 0.7; stiffness: 420; epsilon: 0.3 }
            readonly property real peak: {
                let k = 1;
                for (const it of win.items) k = Math.max(k, win.swell(dock.slots.at[it.key] ?? -1e6));
                return k;
            }
            SpringValue { id: pillH; target: win.sz * dock.peak + 2 * win.pad; damping: 0.62; stiffness: 520; epsilon: 0.2 }
            width: dockW.value
            height: pillH.value
            x: (win.width - width) / 2
            y: win.height - height - 12 - win.lift + (1 - reveal.value) * (win.dockH + 24)
            opacity: Math.min(1, reveal.value * 2)

            RectangularShadow {
                anchors.fill: bg
                radius: bg.radius
                offset.y: 3
                blur: 14
                color: Qt.alpha(Colors.m3shadow, 0.4)
            }
            Rectangle {
                id: bg
                anchors.fill: parent
                radius: Math.min(height / 2, Shape.extraLarge)
                color: Colors.m3surfaceContainer
            }

            Repeater {
                model: ScriptModel { values: win.items; objectProp: "key" }

                Item {
                    id: slot
                    required property var modelData
                    required property int index
                    readonly property var it: modelData
                    readonly property bool held: drag.key === it.key
                    readonly property real restX: dock.slots.at[it.key] ?? 0
                    readonly property real k: win.swell(cx.value)

                    SpringValue { id: cx; target: slot.held ? drag.x : slot.restX; damping: slot.held ? 0.9 : 0.66; stiffness: slot.held ? 1800 : 460; epsilon: 0.2 }
                    SpringValue { id: size; target: win.sz * (slot.held ? (drag.away ? 0.7 : 1.15) : slot.k); damping: 0.62; stiffness: 520; epsilon: 0.1 }
                    SpringValue { id: hop; target: 0; damping: 0.3; stiffness: 260; epsilon: 0.2 }
                    SpringValue { id: born; target: 1; damping: 0.6; stiffness: 420; Component.onCompleted: { value = 0; running = true; } }

                    z: held ? 10 : 0
                    width: size.value
                    height: size.value
                    x: cx.value - width / 2
                    y: (slot.held ? Math.min(win.pad, drag.y) : dock.height - win.pad - height) + hop.value
                    scale: Math.min(1, born.value)
                    opacity: slot.held && drag.away ? 0.5 : 1
                    rotation: Math.max(-1, Math.min(1, cx.velocity / 2500)) * 10

                    IconImage {
                        anchors.fill: parent
                        source: Quickshell.iconPath(slot.it.entry?.icon ?? Apps.iconFor(slot.it.appId), "application-x-executable")
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 2
                        spacing: 3
                        visible: !slot.held
                        Repeater {
                            model: Math.min(3, slot.it.windows.length)
                            Rectangle {
                                required property int index
                                readonly property bool lit: win.focusedKey === slot.it.key && index === 0
                                SpringValue { id: dw; target: lit ? 14 : 5; damping: 0.6; stiffness: 600 }
                                width: dw.value
                                height: 5
                                radius: 2.5
                                color: lit ? Colors.m3primary : Colors.m3onSurfaceVariant
                            }
                        }
                    }

                    Rectangle {
                        visible: tipIn.value > 0.02
                        SpringValue { id: tipIn; target: tap.hovered && drag.key === "" && menu.item === null ? 1 : 0; damping: 0.7; stiffness: 520 }
                        opacity: Math.min(1, tipIn.value)
                        scale: 0.8 + 0.2 * tipIn.value
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -height - 10
                        width: tipText.implicitWidth + 24
                        height: 30
                        radius: 15
                        color: Colors.m3inverseSurface
                        MText { id: tipText; anchors.centerIn: parent; textStyle: Type.labelLarge; color: Colors.m3inverseOnSurface; text: slot.it.entry?.name ?? Apps.nameFor(slot.it.appId) }
                    }

                    HoverHandler { id: tap; cursorShape: dragH.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onTapped: (ev, button) => {
                            if (button === Qt.RightButton) { menu.open(slot); return; }
                            if (button === Qt.MiddleButton) { if (slot.it.entry) { Apps.launch(slot.it.entry); hop.velocity = -700; hop.running = true; } return; }
                            if (win.activate(slot.it)) { hop.velocity = -700; hop.running = true; }
                        }
                    }
                    DragHandler {
                        id: dragH
                        target: null
                        onActiveChanged: {
                            if (active) {
                                const p = slot.mapToItem(dock, centroid.position.x, centroid.position.y);
                                drag.x = p.x; drag.y = win.pad; drag.to = slot.index; drag.key = slot.it.key;
                                return;
                            }
                            const key = drag.key, to = drag.to, away = drag.away;
                            drag.key = "";
                            if (away) { if (slot.it.pinned) win.setPinned(win.pinned.filter(k => k !== key)); return; }
                            const keys = win.items.map(i => i.key).filter(k => k !== key);
                            keys.splice(Math.max(0, Math.min(to, keys.length)), 0, key);
                            win.setPinned(keys.filter(k => k === key ? true : win.pinned.indexOf(k) >= 0));
                        }
                        onCentroidChanged: {
                            if (!active) return;
                            const p = slot.mapToItem(dock, centroid.position.x, centroid.position.y);
                            drag.x = p.x;
                            drag.y = p.y - win.sz / 2;
                            let i = 0, x = win.pad;
                            for (const other of win.items) {
                                if (other.key === drag.key) continue;
                                if (p.x < x + win.sz / 2) break;
                                x += win.sz + 8;
                                i++;
                            }
                            drag.to = i;
                        }
                    }
                }
            }
        }

        QtObject {
            id: menu
            property Item item: null
            function open(slot) { item = slot; menuIn.target = 1; }
            function close() { menuIn.target = 0; }
        }
        SpringValue { id: menuIn; target: 0; damping: 0.7; stiffness: 520; onRunningChanged: if (!running && target === 0) menu.item = null }
        MouseArea {
            anchors.fill: parent
            enabled: menu.item !== null
            acceptedButtons: Qt.AllButtons
            onClicked: menu.close()
        }
        Rectangle {
            id: menuCard
            visible: menu.item !== null
            readonly property var it: menu.item?.it ?? null
            width: 220
            height: menuCol.implicitHeight + 16
            radius: Shape.large
            color: Colors.m3surfaceContainerHigh
            x: menu.item ? Math.max(8, Math.min(win.width - width - 8, dock.x + menu.item.x + menu.item.width / 2 - width / 2)) : 0
            y: dock.y - height - 12
            opacity: Math.min(1, menuIn.value * 1.4)
            scale: 0.85 + 0.15 * menuIn.value
            transformOrigin: Item.Bottom

            Column {
                id: menuCol
                x: 8; y: 8
                width: parent.width - 16
                MText { leftPadding: 12; topPadding: 4; bottomPadding: 6; textStyle: Type.labelLargeEmph; color: Colors.m3primary; text: menuCard.it?.entry?.name ?? Apps.nameFor(menuCard.it?.appId) }
                Repeater {
                    model: menuCard.it ? [
                        { icon: menuCard.it.pinned ? "keep_off" : "keep", label: menuCard.it.pinned ? "Открепить" : "Закрепить", act: () => win.togglePin(menuCard.it) },
                        { icon: "add", label: "Новое окно", act: () => { if (menuCard.it.entry) Apps.launch(menuCard.it.entry); }, show: !!menuCard.it.entry },
                        { icon: "close", label: menuCard.it.windows.length > 1 ? "Закрыть все окна" : "Закрыть", act: () => win.closeAll(menuCard.it), show: menuCard.it.windows.length > 0 }
                    ].filter(a => a.show !== false) : []
                    Item {
                        required property var modelData
                        width: menuCol.width
                        height: 44
                        StateLayer { radius: Shape.medium; onClicked: { parent.modelData.act(); menu.close(); } }
                        MIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; icon: parent.modelData.icon; size: 20; color: Colors.m3onSurfaceVariant }
                        MText { x: 44; anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLarge; text: parent.modelData.label }
                    }
                }
            }
        }
    }
}

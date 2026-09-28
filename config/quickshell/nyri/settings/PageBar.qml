import QtQuick
import QtQuick.Effects
import qs.theme
import qs.services
import qs.widgets

Column {
    id: page
    spacing: 24

    readonly property var info: ({
        launcher: { icon: "apps", label: "Приложения" },
        workspaces: { icon: "view_week", label: "Столы" },
        title: { icon: "web_asset", label: "Окно" },
        clock: { icon: "schedule", label: "Часы" },
        live: { icon: "bubble_chart", label: "Живой остров" },
        tray: { icon: "more_horiz", label: "Трей" },
        status: { icon: "battery_full", label: "Статус" },
        control: { icon: "tune", label: "Шторка" },
        weather: { icon: "partly_cloudy_day", label: "Погода" },
        media: { icon: "music_note", label: "Музыка" }
    })
    readonly property var all: Object.keys(info)
    function ids(zone) {
        if (zone === "hidden") {
            const used = [].concat(ids("left"), ids("center"), ids("right"));
            return all.filter(i => used.indexOf(i) < 0);
        }
        const v = Config.o.bar[zone];
        return Array.isArray(v) ? v : ({ left: ["launcher", "workspaces", "title"], center: ["clock", "live"], right: ["tray", "status", "control"] })[zone];
    }
    function move(id, zone, index) {
        const next = {};
        for (const z of ["left", "center", "right"]) next[z] = ids(z).filter(i => i !== id);
        if (zone !== "hidden") {
            const list = next[zone];
            list.splice(Math.max(0, Math.min(index, list.length)), 0, id);
        }
        Config.o.bar.left = next.left;
        Config.o.bar.center = next.center;
        Config.o.bar.right = next.right;
    }

    property string held: ""
    property real heldW: 0
    property point pointer: Qt.point(0, 0)
    property string overZone: ""
    property int overIndex: -1
    property point grab: Qt.point(0, 0)
    property string landing: ""
    property var zoneItems: ({})
    function drop(id, zone, index, moved) {
        overZone = "";
        landing = id;
        held = "";
        if (moved) move(id, zone, index);
        Qt.callLater(() => ghostRef.land(slotIn(zone, id)));
    }
    property Item ghostRef: null
    function slotIn(zone, id) {
        const box = zoneItems[zone];
        if (!box) return Qt.point(0, 0);
        const list = ids(zone);
        let x = 12;
        for (const i of list) { if (i === id) break; x += chipWidth(i) + 8; }
        return box.mapToItem(editor, x, 30);
    }

    property var labelW: ({})
    function chipWidth(id) { return (labelW[id] ?? 60) + 16 + 20 + 8 + 16; }
    Item {
        width: 0
        height: 0
        visible: false
        Repeater {
            model: page.all
            MText {
                required property string modelData
                textStyle: Type.labelLargeEmph
                text: page.info[modelData].label
                Component.onCompleted: { const m = Object.assign({}, page.labelW); m[modelData] = Math.ceil(implicitWidth); page.labelW = m; }
            }
        }
    }

    Rectangle {
        id: editor
        width: parent.width
        height: zones.implicitHeight + 32
        radius: Shape.extraLarge
        color: Colors.m3surfaceContainer

        Column {
            id: zones
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 12

            MText {
                textStyle: Type.bodyMedium
                color: Colors.m3onSurfaceVariant
                text: "Перетаскивайте кусочки панели между местами"
            }

            Repeater {
                model: [{ zone: "left", label: "Слева" }, { zone: "center", label: "В центре" }, { zone: "right", label: "Справа" }, { zone: "hidden", label: "Спрятано" }]

                Rectangle {
                    id: zoneBox
                    required property var modelData
                    readonly property string zone: modelData.zone
                    readonly property var list: page.ids(zone)
                    readonly property var vis: list.filter(i => i !== page.held)
                    readonly property bool hot: page.held !== "" && page.overZone === zone
                    width: zones.width
                    height: 76
                    radius: Shape.large
                    Component.onCompleted: { const m = Object.assign({}, page.zoneItems); m[zone] = zoneBox; page.zoneItems = m; }
                    SpringValue { id: swell; target: zoneBox.hot ? 1 : 0; damping: 0.55; stiffness: 520 }
                    scale: 1 + 0.015 * swell.value
                    border.width: zone === "hidden" ? 2 : 2 * swell.value
                    border.color: zoneBox.hot ? Colors.m3primary : Colors.m3outlineVariant
                    color: hot ? Colors.m3secondaryContainer : zone === "hidden" ? "transparent" : Colors.m3surfaceContainerHigh
                    Behavior on color { ColorAnim {} }

                    MText {
                        x: 16
                        y: 8
                        textStyle: Type.labelMedium
                        color: zoneBox.hot ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                        text: zoneBox.modelData.label
                    }

                    function indexAt(px) {
                        let x = 12;
                        for (let k = 0; k < vis.length; k++) {
                            const w = page.chipWidth(vis[k]);
                            if (px < x + w / 2) return k;
                            x += w + 8;
                        }
                        return vis.length;
                    }
                    readonly property point local: mapFromItem(editor, page.pointer.x, page.pointer.y)
                    readonly property bool under: page.held !== "" && local.y >= 0 && local.y < height && local.x >= 0 && local.x < width
                    onUnderChanged: if (under) page.overZone = zone; else if (page.overZone === zone) page.overZone = "";
                    onLocalChanged: if (under) page.overIndex = indexAt(local.x)

                    Repeater {
                        model: zoneBox.list
                        BarChip {
                            required property string modelData
                            chipId: modelData
                            zone: zoneBox.zone
                            readonly property int visIndex: zoneBox.vis.indexOf(modelData)
                            readonly property real slotX: {
                                let x = 12;
                                for (let k = 0; k < visIndex; k++) x += page.chipWidth(zoneBox.vis[k]) + 8;
                                return x;
                            }
                            readonly property bool pushed: zoneBox.hot && visIndex >= page.overIndex
                            homeX: slotX + (pushed ? page.heldW + 8 : 0)
                            homeY: 30
                        }
                    }
                }
            }
        }

        Item {
            id: ghost
            z: 100
            readonly property string id_: page.held || page.landing
            visible: id_ !== ""
            width: page.chipWidth(id_)
            height: 36
            property bool flying: false
            property point dest: Qt.point(0, 0)
            function snap(x, y) { gx.value = x; gy.value = y; gx.velocity = 0; gy.velocity = 0; flying = false; }
            function land(p) { dest = p; flying = true; }
            SpringValue {
                id: gx
                target: ghost.flying ? ghost.dest.x : page.pointer.x - page.grab.x
                damping: ghost.flying ? 0.62 : 0.85; stiffness: ghost.flying ? 520 : 1800; epsilon: 0.3
                onRunningChanged: if (!running && ghost.flying) ghost.done()
            }
            SpringValue {
                id: gy
                target: ghost.flying ? ghost.dest.y : page.pointer.y - page.grab.y
                damping: ghost.flying ? 0.62 : 0.85; stiffness: ghost.flying ? 520 : 1800; epsilon: 0.3
            }
            function done() { flying = false; page.landing = ""; }
            Component.onCompleted: page.ghostRef = ghost
            Timer { running: page.landing !== "" && !ghost.flying; interval: 400; onTriggered: ghost.done() }
            Timer { running: ghost.flying; interval: 700; onTriggered: ghost.done() }
            x: gx.value
            y: gy.value

            SpringValue { id: gLift; target: page.held !== "" ? 1 : 0; damping: 0.5; stiffness: 600 }
            readonly property real lean: Math.max(-1, Math.min(1, gx.velocity / 2200))
            readonly property real fall: Math.max(-1, Math.min(1, gy.velocity / 2200))
            rotation: lean * 10
            transform: Scale {
                origin.x: ghost.width / 2
                origin.y: ghost.height / 2
                xScale: 1 + gLift.value * 0.1 + Math.abs(ghost.lean) * 0.1 - Math.abs(ghost.fall) * 0.05
                yScale: 1 + gLift.value * 0.1 - Math.abs(ghost.lean) * 0.07 + Math.abs(ghost.fall) * 0.08
            }

            RectangularShadow {
                anchors.fill: face
                radius: height / 2
                offset.y: 4 + 6 * gLift.value
                blur: 8 + 14 * gLift.value
                color: Qt.alpha(Colors.m3shadow, 0.45 * Math.max(0, gLift.value))
            }
            PieceFace { id: face; anchors.fill: parent; chipId: ghost.id_; lifted: page.held !== "" }
        }
    }

    component BarChip: Item {
        id: chip
        property string chipId
        property string zone
        property real homeX: 0
        property real homeY: 0
        readonly property bool dragging: drag.active

        width: page.chipWidth(chipId)
        height: 36
        opacity: dragging || page.landing === chipId ? 0 : 1

        SpringValue { id: sx; target: chip.homeX; damping: 0.62; stiffness: 420; epsilon: 0.1 }
        SpringValue { id: sy; target: chip.homeY; damping: 0.62; stiffness: 420; epsilon: 0.1 }
        Component.onCompleted: { sx.value = homeX; sy.value = homeY; }
        x: sx.value
        y: sy.value

        rotation: Math.max(-1, Math.min(1, sx.velocity / 3000)) * 4

        PieceFace { anchors.fill: parent; chipId: chip.chipId; lifted: false; dim: chip.zone === "hidden" }

        HoverHandler { cursorShape: chip.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor }
        DragHandler {
            id: drag
            target: null
            onCentroidChanged: if (active) page.pointer = chip.mapToItem(editor, centroid.position.x, centroid.position.y)
            onActiveChanged: {
                if (active) {
                    page.grab = Qt.point(centroid.pressPosition.x, centroid.pressPosition.y);
                    page.pointer = chip.mapToItem(editor, centroid.position.x, centroid.position.y);
                    const at = chip.mapToItem(editor, 0, 0);
                    ghost.snap(at.x, at.y);
                    page.heldW = chip.width;
                    page.held = chip.chipId;
                } else {
                    page.drop(page.held, page.overZone || chip.zone, page.overIndex, page.overZone !== "");
                }
            }
        }
    }

    component PieceFace: Rectangle {
        property string chipId
        property bool lifted: false
        property bool dim: false
        radius: height / 2
        color: lifted ? Colors.m3primary : dim ? Colors.m3surfaceContainerHighest : Colors.m3secondaryContainer
        Behavior on color { ColorAnim {} }
        Row {
            anchors.centerIn: parent
            spacing: 8
            MIcon { anchors.verticalCenter: parent.verticalCenter; icon: page.info[parent.parent.chipId]?.icon ?? ""; size: 20; fill: 1; color: parent.parent.lifted ? Colors.m3onPrimary : Colors.m3onSecondaryContainer }
            MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLargeEmph; color: parent.parent.lifted ? Colors.m3onPrimary : Colors.m3onSecondaryContainer; text: page.info[parent.parent.chipId]?.label ?? parent.parent.chipId }
        }
    }

    ListGroup {
        width: parent.width
        title: "Вид"

        SettingRow {
            icon: "style"
            title: "Стиль"
            subtitle: "Островки, сплошная полоса или прозрачные островки с обводкой"
            below: SegmentedButtons {
                width: parent.width
                value: Config.o.bar.style
                options: [{ value: "islands", label: "Островки" }, { value: "strip", label: "Полоса" }, { value: "outline", label: "Обводка" }]
                onSelected: v => Config.o.bar.style = v
            }
        }

        SettingRow {
            icon: "view_week"
            title: "Рабочие столы"
            below: SegmentedButtons {
                width: parent.width
                value: Config.o.bar.workspaces
                options: [{ value: "pills", label: "Пилюли" }, { value: "numbers", label: "Цифры" }, { value: "dots", label: "Точки" }]
                onSelected: v => Config.o.bar.workspaces = v
            }
        }

        SettingRow {
            icon: "vertical_align_top"
            title: "Прятать панель"
            subtitle: "Выезжает сверху, когда ведёшь мышь к краю, открываешь меню или стол пуст"
            MSwitch { checked: Config.o.bar.autohide; onToggled: c => Config.o.bar.autohide = c }
        }

        SettingRow {
            icon: "rounded_corner"
            title: "Скруглённые углы экрана"
            subtitle: "Как у телефона, даже в полноэкранных приложениях"
            MSwitch { checked: Config.o.bar.corners; onToggled: c => Config.o.bar.corners = c }
        }
    }

    ListGroup {
        width: parent.width
        title: "Детали"

        SettingRow {
            icon: "calendar_today"
            title: "Дата у часов"
            MSwitch { checked: Config.o.bar.date; onToggled: c => Config.o.bar.date = c }
        }
        SettingRow {
            icon: "timer"
            title: "Секунды"
            subtitle: "Часы тикают каждую секунду"
            MSwitch { checked: Config.o.bar.seconds; onToggled: c => Config.o.bar.seconds = c }
        }
        SettingRow {
            icon: "keyboard"
            title: "Раскладка"
            subtitle: "EN / RU в статусе"
            MSwitch { checked: Config.o.bar.layout; onToggled: c => Config.o.bar.layout = c }
        }
        SettingRow {
            icon: "volume_up"
            title: "Громкость"
            subtitle: "Колёсиком меняется, кликом выключается"
            MSwitch { checked: Config.o.bar.volume; onToggled: c => Config.o.bar.volume = c }
        }
        SettingRow {
            icon: "percent"
            title: "Проценты батареи"
            MSwitch { checked: Config.o.bar.percent; onToggled: c => Config.o.bar.percent = c }
        }
        SettingRow {
            icon: "music_note"
            title: "Название трека"
            subtitle: "На острове музыки"
            MSwitch { checked: Config.o.bar.mediaTitle; onToggled: c => Config.o.bar.mediaTitle = c }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.theme
import qs.services
import qs.widgets
import qs.control

// Widgets that live on the wallpaper, Pixel-style: clock, date and weather,
// battery, the player when something plays, the forecast, a calendar, system
// load and today's screen time. Drag them anywhere; right click one for its
// next look. They stay where you put them; only the picture behind drifts
// with the workspace.
//
// Nothing here ticks on its own: the clock wakes once a minute, weather and
// battery are pushed by their services, the player asks for its position and
// the system widget samples CPU and memory only while the desk is bare.
Item {
    id: root

    property real shiftX: 0
    property real shiftY: 0
    property bool bare: true         // no windows on this workspace: widgets are in view

    readonly property var cfg: Config.o.desktop
    visible: cfg.enabled

    // First appearance: everything drops in one after another.
    property bool shown: false
    SpringValue { id: introSpring; target: root.shown ? 1 : 0; damping: 0.7; stiffness: 200 }
    Component.onCompleted: shown = true
    Connections {
        target: Lock
        function onUnlocked() { introSpring.value = 0; introSpring.running = true; }
    }
    function stage(i) { return Math.max(0, Math.min(1.2, introSpring.value * 1.5 - i * 0.12)); }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // CPU and memory are sampled only while the system widget is in view.
    readonly property bool watchingSys: cfg.enabled && cfg.system && bare
    onWatchingSysChanged: SysStats.watchers += watchingSys ? 1 : -1
    Component.onDestruction: if (watchingSys) SysStats.watchers--

    readonly property var battery: UPower.displayDevice
    readonly property real level: {
        const p = battery?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
                                  || battery?.state === UPowerDeviceState.PendingCharge
                                  || battery?.state === UPowerDeviceState.FullyCharged
    readonly property string batteryNote: charging
        ? (battery?.timeToFull > 0 ? "до полной " + duration(battery.timeToFull) : "заряжается")
        : (battery?.timeToEmpty > 0 ? "ещё " + duration(battery.timeToEmpty) : Power.label)

    readonly property string dateLine: {
        const s = clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }
    readonly property var now: Weather.ready ? Weather.describe(Weather.current.code, Weather.current.day) : null

    function duration(s) {
        if (!s || s <= 0) return "";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return h > 0 ? h + " ч " + m + " мин" : m + " мин";
    }

    // ── Grid, shown only while something is being dragged ───────────────
    readonly property var desks: [dClock, dGlance, dBattery, dMedia, dForecast, dCalendar, dSystem, dUsage]
    readonly property DeskItem held: desks.find(d => d.dragging) ?? null
    SpringValue { id: gridIn; target: root.held && root.cfg.grid ? 1 : 0; damping: 0.9; stiffness: 400 }

    Canvas {
        id: grid
        anchors.fill: parent
        opacity: gridIn.value
        visible: opacity > 0.01
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const g = root.cfg.gridSize;
            if (g <= 0) return;
            ctx.fillStyle = Qt.alpha(Colors.m3onSurface, 0.35);
            for (let x = 0; x <= width; x += g)
                for (let y = 0; y <= height; y += g)
                    ctx.fillRect(x - 1.5, y - 1.5, 3, 3);
        }
    }

    // Where the held widget will land: a soft slot that hops cell to cell.
    Rectangle {
        visible: root.held !== null
        SpringValue { id: slotX; target: root.held ? root.held.dropX : 0; damping: 0.7; stiffness: 700 }
        SpringValue { id: slotY; target: root.held ? root.held.dropY : 0; damping: 0.7; stiffness: 700 }
        x: slotX.value + root.shiftX
        y: slotY.value + root.shiftY
        width: root.held?.width ?? 0
        height: root.held?.height ?? 0
        radius: Math.min(height / 2, Shape.extraLarge)
        color: Qt.alpha(Colors.m3primaryContainer, 0.35)
        border.width: 2
        border.color: Qt.alpha(Colors.m3primary, 0.6)
    }

    // Input only where the widgets are (see the window in Wallpaper.qml).
    readonly property Region mask: Region {
        Region { item: dClock }
        Region { item: dGlance }
        Region { item: dBattery }
        Region { item: dMedia }
        Region { item: dForecast }
        Region { item: dCalendar }
        Region { item: dSystem }
        Region { item: dUsage }
        Region { item: menu.open ? catcher : null }
        Region { item: menu.visible ? menu : null }
    }

    // While the menu is open, a click anywhere else closes it.
    MouseArea {
        id: catcher
        anchors.fill: parent
        enabled: menu.open
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: menu.close()
    }

    // Scripted demo requests (test window only; see services/Demo.qml).
    Connections {
        target: Demo
        function find(key) { return root.desks.find(d => d.key === key) ?? null; }
        function onMenuRequested(key) { const d = find(key); if (d) menu.openFor(d); }
        function onMenuClose() { menu.close(); }
        function onLookRequested(key, index) { const d = find(key); if (d) d.setVariant(index); }
        function onDragRequested(key, x, y) { const d = find(key); if (d) d.demoDrag(x, y); }
    }

    // Hand angles for the analog clock, counted from midnight so they only
    // ever move forward (no spin backwards when the hour turns).
    readonly property int dayMinutes: clock.date.getHours() * 60 + clock.date.getMinutes()
    readonly property real minuteAngle: dayMinutes * 6
    readonly property real hourAngle: dayMinutes * 0.5

    Item {
        id: col
        anchors.fill: parent

        // ── Clock ───────────────────────────────────────────────────────
        DeskItem {
            id: dClock
            shown: root.cfg.clock
            key: "clock"
            desk: root
            defaultY: 112
            title: "Часы"
            variantNames: ["Печенька", "Строка", "Стрелки", "Две фигуры"]
            onMenuRequested: menu.openFor(dClock)
            looks: [clockCookie, clockPill, clockAnalog, clockDuo]

            Item {
                readonly property Item cur: loaderClock.item
                Loader { id: loaderClock; sourceComponent: dClock.looks[dClock.variant] ?? null }
                width: cur?.width ?? 0
                height: cur?.height ?? 0
                opacity: Math.min(1, root.stage(0))
                scale: 0.6 + 0.4 * root.stage(0)
                transformOrigin: Item.TopLeft

                // 1. Hours over minutes inside a cookie that turns a notch a minute.
                Component {
                    id: clockCookie
                    Item {
                        width: 260
                        height: 284             // the scallops need air below them

                        SpringValue {
                            id: turn
                            target: (clock.date.getHours() * 60 + clock.date.getMinutes()) * 4
                            damping: 0.55
                            stiffness: 120
                            epsilon: 0.01
                        }
                        MaterialShape {
                            id: cookie
                            width: 260
                            height: 260
                            shape: "cookie12Sided"
                            color: Colors.m3primaryContainer
                            rotation: turn.value % 360
                        }
                        Column {
                            anchors.centerIn: cookie
                            spacing: -34
                            RollingText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                pixelSize: 104
                                weight: 680
                                color: Colors.m3onPrimaryContainer
                                speed: "slow"
                                text: Qt.formatTime(clock.date, "HH")
                            }
                            RollingText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                pixelSize: 104
                                weight: 680
                                color: Colors.m3primary
                                speed: "slow"
                                text: Qt.formatTime(clock.date, "mm")
                            }
                        }
                    }
                }

                // 2. One line in a wide pill, with the weekday under it.
                Component {
                    id: clockPill
                    Rectangle {
                        width: pillCol.implicitWidth + 64
                        height: 150
                        radius: height / 2
                        color: Colors.m3primaryContainer

                        Column {
                            id: pillCol
                            anchors.centerIn: parent
                            spacing: -6
                            RollingText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                pixelSize: 88
                                weight: 680
                                color: Colors.m3onPrimaryContainer
                                speed: "slow"
                                text: Qt.formatTime(clock.date, "HH:mm")
                            }
                            MText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                textStyle: Type.titleMediumEmph
                                color: Colors.m3onPrimaryContainer
                                opacity: 0.8
                                text: root.dateLine
                            }
                        }
                    }
                }

                // 3. Analog: rounded hands on a scalloped face.
                Component {
                    id: clockAnalog
                    Item {
                        width: 240
                        height: 240

                        SpringValue { id: hourS; target: root.hourAngle; damping: 0.55; stiffness: 140; epsilon: 0.01 }
                        SpringValue { id: minS; target: root.minuteAngle; damping: 0.55; stiffness: 140; epsilon: 0.01 }

                        MaterialShape {
                            anchors.fill: parent
                            shape: "cookie9Sided"
                            color: Colors.m3primaryContainer
                        }
                        // Twelve dots for the hours.
                        Repeater {
                            model: 12
                            Rectangle {
                                required property int index
                                readonly property real a: index * Math.PI / 6
                                x: 120 + Math.sin(a) * 88 - width / 2
                                y: 120 - Math.cos(a) * 88 - height / 2
                                width: index % 3 === 0 ? 10 : 6
                                height: width
                                radius: width / 2
                                color: Colors.m3onPrimaryContainer
                                opacity: index % 3 === 0 ? 0.9 : 0.45
                            }
                        }
                        Rectangle {                     // hour hand
                            x: 120 - width / 2
                            y: 120 - height + 10
                            width: 18
                            height: 70
                            radius: 9
                            color: Colors.m3onPrimaryContainer
                            transform: Rotation { origin.x: 9; origin.y: 60; angle: hourS.value }
                        }
                        Rectangle {                     // minute hand
                            x: 120 - width / 2
                            y: 120 - height + 8
                            width: 10
                            height: 96
                            radius: 5
                            color: Colors.m3primary
                            transform: Rotation { origin.x: 5; origin.y: 88; angle: minS.value }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            radius: 11
                            color: Colors.m3primary
                            border.width: 5
                            border.color: Colors.m3primaryContainer
                        }
                    }
                }

                // 4. Two shapes side by side: hours in a cookie, minutes in a pill.
                Component {
                    id: clockDuo
                    Row {
                        spacing: -18
                        MaterialShape {
                            width: 168
                            height: 168
                            shape: "cookie9Sided"
                            color: Colors.m3primaryContainer
                            RollingText { anchors.centerIn: parent; pixelSize: 78; weight: 700; color: Colors.m3onPrimaryContainer; speed: "slow"; text: Qt.formatTime(clock.date, "HH") }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: 150
                            height: 150
                            radius: Shape.extraLarge * 1.6
                            color: Colors.m3secondaryContainer
                            RollingText { anchors.centerIn: parent; pixelSize: 70; weight: 700; color: Colors.m3onSecondaryContainer; speed: "slow"; text: Qt.formatTime(clock.date, "mm") }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.open("dashboard")
                }
            }
        }

        // ── At a glance: date, weather ──────────────────────────────────
        DeskItem {
            id: dGlance
            shown: root.cfg.glance
            key: "glance"
            desk: root
            defaultY: 412
            title: "Дата и погода"
            variantNames: ["Строка", "Карточка", "Только дата"]
            onMenuRequested: menu.openFor(dGlance)
            looks: [glancePill, glanceCard, glanceDate]

            Item {
                readonly property Item cur: loaderGlance.item
                Loader { id: loaderGlance; sourceComponent: dGlance.looks[dGlance.variant] ?? null }
                width: cur?.width ?? 0
                height: cur?.height ?? 0
                opacity: Math.min(1, root.stage(1))
                transform: Translate { y: (1 - Math.min(1, root.stage(1))) * 24 }

                // 1. One line in a pill.
                Component {
                    id: glancePill
                    Rectangle {
                        width: glanceRow.implicitWidth + 40
                        height: 56
                        radius: height / 2
                        color: Colors.m3surfaceContainer

                        Row {
                            id: glanceRow
                            anchors.centerIn: parent
                            spacing: 12
                            MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.titleMediumEmph; text: root.dateLine }
                            Rectangle { visible: Weather.ready; anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: Colors.m3outline }
                            Row {
                                visible: Weather.ready
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                MIcon { anchors.verticalCenter: parent.verticalCenter; icon: root.now?.icon ?? ""; size: 24; fill: 1; color: Colors.m3primary }
                                RollingText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.titleMediumEmph; text: Weather.ready ? Weather.current.temp + "°" : "" }
                            }
                        }
                    }
                }

                // 3. Only the date, big and quiet.
                Component {
                    id: glanceDate
                    Rectangle {
                        width: dateOnly.implicitWidth + 48
                        height: 64
                        radius: height / 2
                        color: Colors.m3surfaceContainer
                        MText { id: dateOnly; anchors.centerIn: parent; textStyle: ({ size: 22, weight: 650, rond: 100 }); text: root.dateLine }
                    }
                }

                // 2. A card: the day number big, weekday and month, weather.
                Component {
                    id: glanceCard
                    Rectangle {
                        width: 300
                        height: 132
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        MText {
                            id: dayNum
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 72
                            font.variableAxes: ({ "wght": 650 })
                            color: Colors.m3primary
                            text: clock.date.getDate()
                        }
                        Column {
                            anchors.left: dayNum.right
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            MText {
                                textStyle: Type.titleMediumEmph
                                text: { const s = clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd"); return s.charAt(0).toUpperCase() + s.slice(1); }
                            }
                            MText { textStyle: Type.bodyMedium; color: Colors.m3onSurfaceVariant; text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "MMMM yyyy") }
                            Row {
                                visible: Weather.ready
                                spacing: 6
                                topPadding: 4
                                MIcon { anchors.verticalCenter: parent.verticalCenter; icon: root.now?.icon ?? ""; size: 20; fill: 1; color: Colors.m3primary }
                                MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLargeEmph; text: Weather.ready ? Weather.current.temp + "° · " + root.now.text : "" }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.open("dashboard")
                }
            }
        }

        // ── Battery ─────────────────────────────────────────────────────
        DeskItem {
            id: dBattery
            shown: root.cfg.battery && (root.battery?.isLaptopBattery ?? false)
            key: "battery"
            desk: root
            defaultY: 484
            title: "Батарея"
            variantNames: ["Кольцо и время", "Большое кольцо", "Батарейка"]
            onMenuRequested: menu.openFor(dBattery)
            looks: [battPill, battRing, battBar]

            Item {
                readonly property Item cur: loaderBattery.item
                Loader { id: loaderBattery; sourceComponent: dBattery.looks[dBattery.variant] ?? null }
                width: cur?.width ?? 0
                height: cur?.height ?? 0
                opacity: Math.min(1, root.stage(2))
                transform: Translate { y: (1 - Math.min(1, root.stage(2))) * 24 }

                // 1. A ring with the number, and how long it lasts.
                Component {
                    id: battPill
                    Rectangle {
                        width: battRow.implicitWidth + 24
                        height: 72
                        radius: height / 2
                        color: Colors.m3surfaceContainer

                        Row {
                            id: battRow
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14
                            Item {
                                width: 56
                                height: 56
                                CircularProgress {
                                    anchors.fill: parent
                                    stroke: 6
                                    value: root.level
                                    activeColor: root.level <= 0.15 && !root.charging ? Colors.m3error : Colors.m3primary
                                }
                                MIcon {
                                    anchors.centerIn: parent
                                    icon: root.charging ? "bolt" : root.level <= 0.15 ? "battery_alert" : "battery_full"
                                    size: 22
                                    fill: 1
                                    color: root.charging ? Colors.m3primary : Colors.m3onSurfaceVariant
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                RollingText { textStyle: Type.titleMediumEmph; text: Math.round(root.level * 100) + "%" }
                                FlowText { textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: root.batteryNote }
                            }
                            Item { width: 4; height: 1 }
                        }
                    }
                }

                // 3. A battery: a wide pill that fills, the number on it.
                Component {
                    id: battBar
                    Rectangle {
                        width: 220
                        height: 76
                        radius: height / 2
                        color: Colors.m3surfaceContainer
                        Rectangle {
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 16
                            height: parent.height - 16
                            radius: height / 2
                            color: Colors.m3secondaryContainer
                            Rectangle {
                                SpringValue { id: battFill; target: root.level; damping: 0.9; stiffness: 60; epsilon: 0.001 }
                                width: Math.max(height, parent.width * battFill.value)
                                height: parent.height
                                radius: height / 2
                                color: root.level <= 0.15 && !root.charging ? Colors.m3error : Colors.m3primary
                            }
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                // The number sits over the fill once it passes the middle.
                                MIcon { anchors.verticalCenter: parent.verticalCenter; visible: root.charging; icon: "bolt"; size: 22; fill: 1; color: root.level > 0.5 ? Colors.m3onPrimary : Colors.m3onSecondaryContainer }
                                RollingText { anchors.verticalCenter: parent.verticalCenter; pixelSize: 26; weight: 700; color: root.level > 0.5 ? Colors.m3onPrimary : Colors.m3onSecondaryContainer; text: Math.round(root.level * 100) + "%" }
                            }
                        }
                    }
                }

                // 2. One big ring, the number inside.
                Component {
                    id: battRing
                    Rectangle {
                        width: 150
                        height: 150
                        radius: width / 2
                        color: Colors.m3surfaceContainer

                        CircularProgress {
                            anchors.fill: parent
                            anchors.margins: 12
                            stroke: 10
                            value: root.level
                            activeColor: root.level <= 0.15 && !root.charging ? Colors.m3error : Colors.m3primary
                        }
                        Column {
                            anchors.centerIn: parent
                            MIcon { anchors.horizontalCenter: parent.horizontalCenter; visible: root.charging; icon: "bolt"; size: 20; fill: 1; color: Colors.m3primary }
                            RollingText { anchors.horizontalCenter: parent.horizontalCenter; pixelSize: 34; weight: 650; text: Math.round(root.level * 100) + "%" }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.open("power")
                }
            }
        }

        // ── Now playing: shows up only when there is a player ──────────
        DeskItem {
            id: dMedia
            shown: root.cfg.media
            key: "media"
            desk: root
            defaultY: 572
            title: "Плеер"
            variantNames: []
            onMenuRequested: menu.openFor(dMedia)

            Item {
                id: mediaBox
                width: 380
                readonly property bool wanted: root.cfg.media && Media.player !== null
                SpringValue { id: mediaIn; target: mediaBox.wanted ? 1 : 0; damping: 0.72; stiffness: 260 }
                readonly property real p: Math.max(0, mediaIn.value)
                height: card.implicitHeight * Math.min(1, p)
                visible: p > 0.01
                opacity: Math.min(1, p) * Math.min(1, root.stage(3))

                MediaCard {
                    id: card
                    width: parent.width
                    active: root.bare
                    color: Colors.m3surfaceContainer
                    scale: 0.85 + 0.15 * mediaBox.p
                    transformOrigin: Item.Top
                }
            }
        }

        // ── Right column ───────────────────────────────────────────────

        // Weather.
        DeskItem {
            id: dForecast
            shown: root.cfg.forecast && Weather.daily.length > 0
            key: "forecast"
            desk: root
            defaultX: root.width - 56 - width
            defaultY: 112
            title: "Погода"
            variantNames: ["Пять дней", "Сейчас"]
            onMenuRequested: menu.openFor(dForecast)
            looks: [fcDays, fcNow]

            Item {
                readonly property Item cur: loaderForecast.item
                Loader { id: loaderForecast; sourceComponent: dForecast.looks[dForecast.variant] ?? null }
                width: cur?.width ?? 0
                height: cur?.height ?? 0
                opacity: Math.min(1, root.stage(1))

                // 1. The next five days: big icons, highs over lows.
                Component {
                    id: fcDays
                    Rectangle {
                        width: 360
                        height: 150
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        Row {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            Repeater {
                                model: Weather.daily.slice(0, 5)
                                Column {
                                    required property var modelData
                                    required property int index
                                    width: parent.width / 5
                                    spacing: 6
                                    MText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        textStyle: index === 0 ? Type.labelLargeEmph : Type.labelMedium
                                        color: index === 0 ? Colors.m3primary : Colors.m3onSurfaceVariant
                                        text: index === 0 ? "Сегодня" : Qt.locale("ru_RU").toString(modelData.date, "ddd")
                                    }
                                    MIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: Weather.describe(modelData.code, true).icon; size: 30; fill: 1; color: Colors.m3primary }
                                    MText { anchors.horizontalCenter: parent.horizontalCenter; textStyle: Type.titleMediumEmph; text: modelData.max + "°" }
                                    MText { anchors.horizontalCenter: parent.horizontalCenter; textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: modelData.min + "°" }
                                }
                            }
                        }
                    }
                }

                // 2. Right now: the temperature big, what it feels like.
                Component {
                    id: fcNow
                    Rectangle {
                        width: 300
                        height: 150
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        MIcon {
                            id: nowIcon
                            x: 22
                            anchors.verticalCenter: parent.verticalCenter
                            icon: root.now?.icon ?? "cloud"
                            size: 72
                            fill: 1
                            color: Colors.m3primary
                        }
                        Column {
                            anchors.left: nowIcon.right
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            RollingText { pixelSize: 52; weight: 650; text: Weather.ready ? Weather.current.temp + "°" : "—" }
                            MText { textStyle: Type.labelLargeEmph; text: root.now?.text ?? "" }
                            MText { textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: Weather.ready ? "ощущается " + Weather.current.feels + "° · " + Weather.city : "" }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.open("dashboard")
                }
            }
        }

        // Calendar.
        DeskItem {
            id: dCalendar
            shown: root.cfg.calendar
            key: "calendar"
            desk: root
            defaultX: root.width - 56 - width
            defaultY: 112 + 150 + 16
            title: "Календарь"
            variantNames: ["Месяц", "Неделя"]
            onMenuRequested: menu.openFor(dCalendar)
            looks: [calMonth, calWeek]

            Item {
                readonly property Item cur: loaderCalendar.item
                Loader { id: loaderCalendar; sourceComponent: dCalendar.looks[dCalendar.variant] ?? null }
                width: cur?.width ?? 0
                height: cur?.height ?? 0
                opacity: Math.min(1, root.stage(2))

                // 1. This month, today in a cookie.
                Component {
                    id: calMonth
                    Rectangle {
                        width: 360
                        height: cal.implicitHeight + 32
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        CalendarView {
                            id: cal
                            x: 16
                            y: 16
                            width: parent.width - 32
                            today: clock.date
                        }
                    }
                }

                // 2. This week as a strip.
                Component {
                    id: calWeek
                    Rectangle {
                        id: week
                        width: 360
                        height: 104
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        readonly property date monday: {
                            const d = clock.date;
                            return new Date(d.getFullYear(), d.getMonth(), d.getDate() - (d.getDay() + 6) % 7);
                        }

                        Row {
                            anchors.centerIn: parent
                            Repeater {
                                model: 7
                                Item {
                                    required property int index
                                    readonly property date day: new Date(week.monday.getFullYear(), week.monday.getMonth(), week.monday.getDate() + index)
                                    readonly property bool isToday: day.toDateString() === clock.date.toDateString()
                                    width: (week.width - 24) / 7
                                    height: 80
                                    MText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 4
                                        textStyle: Type.labelMedium
                                        color: parent.isToday ? Colors.m3primary : Colors.m3onSurfaceVariant
                                        text: Qt.locale("ru_RU").toString(parent.day, "ddd")
                                    }
                                    MaterialShape {
                                        visible: parent.isToday
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 30
                                        width: 42
                                        height: 42
                                        shape: "cookie9Sided"
                                        color: Colors.m3primary
                                    }
                                    MText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 30 + (42 - height) / 2
                                        textStyle: Type.titleMediumEmph
                                        color: parent.isToday ? Colors.m3onPrimary : Colors.m3onSurface
                                        text: parent.day.getDate()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // System load.
        DeskItem {
            id: dSystem
            shown: root.cfg.system
            key: "system"
            desk: root
            defaultX: root.width - 56 - width
            defaultY: 112 + 150 + 16 + dCalendar.height + 16
            title: "Система"
            variantNames: ["Кольца", "Полосы", "Строка"]
            onMenuRequested: menu.openFor(dSystem)
            looks: [sysRings, sysBars, sysLine]

            Item {
                id: sysBox
                readonly property var stats: [
                    { label: "ЦП", value: SysStats.cpu },
                    { label: "ОЗУ", value: SysStats.mem },
                    { label: "Диск", value: SysStats.disk }
                ]
                readonly property Item cur: loaderSystem.item
                Loader { id: loaderSystem; sourceComponent: dSystem.looks[dSystem.variant] ?? null }
                width: cur?.width ?? 0
                height: cur?.height ?? 0
                opacity: Math.min(1, root.stage(3))

                // 1. Three rings.
                // Fixed sizes: numbers changing width must never move the card.
                Component {
                    id: sysRings
                    Rectangle {
                        width: 3 * 60 + 2 * 20 + 40
                        height: 112
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        Row {
                            id: sysRow
                            anchors.centerIn: parent
                            spacing: 20
                            Repeater {
                                model: sysBox.stats
                                Column {
                                    required property var modelData
                                    width: 60
                                    spacing: 4
                                    Item {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 60
                                        height: 60
                                        // A slow, calm spring: the 2 s samples glide into each
                                        // other, and the number counts along with the ring.
                                        SpringValue { id: ring; target: modelData.value; damping: 1.0; stiffness: 12; epsilon: 0.001 }
                                        CircularProgress { anchors.fill: parent; stroke: 6; value: ring.value; animated: false }
                                        MText { anchors.centerIn: parent; textStyle: Type.labelLargeEmph; font.features: { "tnum": 1 }; text: Math.round(ring.value * 100) }
                                    }
                                    MText { anchors.horizontalCenter: parent.horizontalCenter; textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: modelData.label }
                                }
                            }
                        }
                    }
                }

                // 3. One line: the numbers only, fixed width.
                Component {
                    id: sysLine
                    Rectangle {
                        width: 300
                        height: 56
                        radius: height / 2
                        color: Colors.m3surfaceContainer
                        Row {
                            anchors.centerIn: parent
                            spacing: 18
                            Repeater {
                                model: sysBox.stats
                                Row {
                                    required property var modelData
                                    spacing: 6
                                    SpringValue { id: lineV; target: modelData.value; damping: 1.0; stiffness: 12; epsilon: 0.001 }
                                    MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: modelData.label }
                                    MText { anchors.verticalCenter: parent.verticalCenter; width: 40; textStyle: Type.titleMediumEmph; font.features: { "tnum": 1 }; text: Math.round(lineV.value * 100) + "%" }
                                }
                            }
                        }
                    }
                }

                // 2. Three bars.
                Component {
                    id: sysBars
                    Rectangle {
                        width: 300
                        height: 128
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            spacing: 12
                            Repeater {
                                model: sysBox.stats
                                Item {
                                    required property var modelData
                                    width: parent.width
                                    height: 22
                                    MText { anchors.verticalCenter: parent.verticalCenter; width: 44; textStyle: Type.labelLargeEmph; text: modelData.label }
                                    Rectangle {
                                        x: 48
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 48 - 44
                                        height: 12
                                        radius: 6
                                        color: Colors.m3secondaryContainer
                                        Rectangle {
                                            SpringValue { id: bar; target: modelData.value; damping: 1.0; stiffness: 12; epsilon: 0.001 }
                                            width: Math.max(12, parent.width * bar.value)
                                            height: parent.height
                                            radius: 6
                                            color: Colors.m3primary
                                        }
                                    }
                                    Item {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 40
                                        height: 20
                                        MText { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLarge; font.features: { "tnum": 1 }; text: Math.round(bar.value * 100) + "%" }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Screen time today.
        DeskItem {
            id: dUsage
            shown: root.cfg.usage
            key: "usage"
            desk: root
            defaultX: root.width - 56 - width
            defaultY: 112 + 150 + 16 + dCalendar.height + 16 + (dSystem.shown ? dSystem.height + 16 : 0)
            title: "Экранное время"
            variantNames: ["Список", "Итог"]
            onMenuRequested: menu.openFor(dUsage)
            looks: [usageList, usageTotal]

            Item {
                id: usage
                // Recomputed when the clock ticks (once a minute): cheap.
                readonly property var today: { clock.date; return ScreenTime.dayTotals(new Date()); }
                readonly property var topApps: Object.entries(today).sort((a, b) => b[1] - a[1]).slice(0, 3)
                readonly property string totalText: ScreenTime.fmt(ScreenTime.total(today))
                readonly property Item cur: loaderUsage.item
                Loader { id: loaderUsage; sourceComponent: dUsage.looks[dUsage.variant] ?? null }
                width: cur?.width ?? 0
                height: cur?.height ?? 0
                opacity: Math.min(1, root.stage(4))

                // 1. The total and the top three apps.
                Component {
                    id: usageList
                    Rectangle {
                        width: 360
                        height: usageCol.implicitHeight + 32
                        radius: Shape.extraLarge
                        color: Colors.m3surfaceContainer

                        Column {
                            id: usageCol
                            x: 20
                            y: 16
                            width: parent.width - 40
                            spacing: 10

                            Row {
                                spacing: 8
                                MIcon { anchors.verticalCenter: parent.verticalCenter; icon: "hourglass_top"; size: 20; fill: 1; color: Colors.m3primary }
                                FlowText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.titleMediumEmph; text: "Сегодня · " + usage.totalText }
                            }
                            Repeater {
                                model: usage.topApps
                                Item {
                                    required property var modelData
                                    width: usageCol.width
                                    height: 28
                                    readonly property real share: modelData[1] / Math.max(1, usage.topApps[0][1])
                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitSize: 22
                                        source: Quickshell.iconPath(Apps.iconFor(modelData[0]), "application-x-executable")
                                    }
                                    Rectangle {
                                        x: 32
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: (parent.width - 32 - 64) * share
                                        height: 10
                                        radius: 5
                                        color: Colors.m3primary
                                        Behavior on width { SpatialAnim {} }
                                    }
                                    MText {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        textStyle: Type.labelMedium
                                        color: Colors.m3onSurfaceVariant
                                        text: ScreenTime.fmt(modelData[1])
                                    }
                                }
                            }
                            MText {
                                visible: usage.topApps.length === 0
                                textStyle: Type.labelMedium
                                color: Colors.m3onSurfaceVariant
                                text: Config.o.screenTime.enabled ? "Пока пусто" : "Учёт выключен в настройках"
                            }
                        }
                    }
                }

                // 2. Just the total, big.
                Component {
                    id: usageTotal
                    Rectangle {
                        width: totalRow.implicitWidth + 48
                        height: 96
                        radius: height / 2
                        color: Colors.m3surfaceContainer

                        Row {
                            id: totalRow
                            anchors.centerIn: parent
                            spacing: 14
                            MaterialShape {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 56
                                height: 56
                                shape: "cookie9Sided"
                                color: Colors.m3primaryContainer
                                MIcon { anchors.centerIn: parent; icon: "hourglass_top"; size: 26; fill: 1; color: Colors.m3onPrimaryContainer }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                FlowText { textStyle: ({ size: 30, weight: 650, rond: 100 }); text: usage.totalText }
                                MText { textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: "за экраном сегодня" }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Right-click menu: this widget's looks as live previews, and remove ──
    Item {
        id: menu

        property DeskItem target: null
        readonly property bool open: target !== null && (openS.target > 0 || openDelay.running)
        // The previews are live copies of the widget; building them takes a
        // frame or two. Build first (invisible), then unfold — otherwise the
        // empty card shows up before its content.
        function openFor(d) { target = d; openS.target = 0; openDelay.restart(); }
        Timer { id: openDelay; interval: 60; onTriggered: openS.target = 1 }
        function close() { openDelay.stop(); openS.target = 0; }

        SpringValue { id: openS; target: 0; damping: 0.7; stiffness: 520; onRunningChanged: if (!running && target === 0 && !openDelay.running) menu.target = null }
        readonly property real p: Math.max(0, openS.value)

        z: 100
        visible: target !== null && p > 0.01
        width: Math.max(240, previews.width + 16)
        height: menuCol.implicitHeight + 16
        // Above the widget, centred on it; below when there is no room.
        readonly property bool below: target ? target.y - height - 8 < 8 : false
        x: target ? Math.max(8, Math.min(root.width - width - 8, target.x + target.width / 2 - width / 2)) : 0
        y: target ? (below ? target.y + target.height + 8 : target.y - height - 8) : 0
        opacity: Math.min(1, p * 1.4)
        scale: 0.85 + 0.15 * p
        transformOrigin: below ? Item.Top : Item.Bottom

        Rectangle {
            anchors.fill: parent
            radius: Shape.large
            color: Colors.m3surfaceContainerHigh
        }

        Column {
            id: menuCol
            x: 8
            y: 8
            width: parent.width - 16

            MText {
                leftPadding: 12
                topPadding: 6
                bottomPadding: 6
                textStyle: Type.labelLargeEmph
                color: Colors.m3primary
                text: menu.target?.title ?? ""
            }

            // Every look as a live miniature; the current one is ringed.
            Grid {
                id: previews
                columns: Math.min(2, menu.target?.looks.length ?? 1)
                spacing: 8
                bottomPadding: 8

                Repeater {
                    model: menu.target?.looks ?? []

                    Item {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool picked: menu.target?.variant === index
                        width: 176
                        height: 138
                        opacity: Math.max(0, Math.min(1, menu.p * 2 - index * 0.2))
                        scale: 0.9 + 0.1 * Math.min(1, Math.max(0, menu.p * 1.5 - index * 0.1))

                        Rectangle {
                            id: box
                            width: parent.width
                            height: 110
                            radius: Shape.large
                            color: tile.picked ? Colors.m3secondaryContainer : Colors.m3surfaceContainerHighest
                            border.width: tile.picked ? 3 : 0
                            border.color: Colors.m3primary
                            clip: true

                            Loader {
                                id: mini
                                sourceComponent: tile.modelData
                                readonly property real k: item ? Math.min(1, (box.width - 20) / item.width, (box.height - 20) / item.height) : 1
                                x: (box.width - (item?.width ?? 0) * k) / 2
                                y: (box.height - (item?.height ?? 0) * k) / 2
                                scale: k
                                transformOrigin: Item.TopLeft
                                enabled: false
                            }
                        }
                        MText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            textStyle: tile.picked ? Type.labelLargeEmph : Type.labelLarge
                            color: tile.picked ? Colors.m3primary : Colors.m3onSurfaceVariant
                            text: menu.target?.variantNames[tile.index] ?? ""
                        }
                        StateLayer {
                            anchors.fill: box
                            radius: Shape.large
                            onClicked: { menu.target.setVariant(tile.index); menu.close(); }
                        }
                    }
                }
            }

            Rectangle {
                visible: (menu.target?.looks.length ?? 0) > 0
                width: parent.width
                height: 1
                color: Colors.m3outlineVariant
            }

            Item {
                width: menuCol.width
                height: 44
                StateLayer {
                    radius: Shape.medium
                    onClicked: {
                        const k = menu.target.key;
                        menu.close();
                        Config.o.desktop[k] = false;
                    }
                }
                MIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; icon: "visibility_off"; size: 20; color: Colors.m3onSurfaceVariant }
                MText { x: 44; anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLarge; text: "Убрать со стола" }
            }
        }
    }
}

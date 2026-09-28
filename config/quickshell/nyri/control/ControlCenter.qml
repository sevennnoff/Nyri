import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.theme
import qs.services
import qs.widgets
import qs.notifications

Surface {
    id: root

    name: "control"

    readonly property var battery: UPower.displayDevice

    property string page: "main"
    property string shownPage: ""
    onPageChanged: { if (page !== "main") shownPage = page; flick.contentY = 0; }
    onOpenChanged: if (open) { origin = null; page = Panels.tab || "main"; }
    SpringValue { id: slide; target: root.page === "main" ? 0 : 1; damping: 0.78; stiffness: 360; epsilon: 0.001 }

    property var origin: null
    function openFrom(tile, pageId) {
        const pt = tile.mapToItem(card, 0, 0);
        origin = { x: pt.x, y: pt.y, w: tile.width, h: tile.height, radius: tile.checked ? tile.height / 2 : Shape.largeIncreased,
                   color: tile.checked ? Colors.m3primary : Colors.m3surfaceContainerHighest,
                   ink: tile.checked ? Colors.m3onPrimary : Colors.m3onSurface, icon: tile.icon, label: tile.label };
        page = pageId;
    }

    readonly property var liveCards: Activities.list.filter(a => a.kind !== "media")

    function duration(sec) {
        const total = Math.round(sec / 60), h = Math.floor(total / 60), m = total % 60;
        return h > 0 ? h + " ч " + m + " мин" : m + " мин";
    }

    Popout {
        id: card

        progress: root.progress
        toX: parent.width - toW - 12
        toW: 420
        toH: Math.min((root.page === "main" ? content.implicitHeight : sub.implicitHeight) + 32, parent.height - toY - 12)

        Behavior on toH { SpatialAnim {} }
        defaultFromX: parent.width - 12 - 200
        defaultFromW: 200

        Rectangle {
            id: morph
            readonly property var o: root.origin
            readonly property real t: Math.max(0, Math.min(1.04, slide.value))
            readonly property real fade: slide.value > 0.55 ? Math.max(0, 1 - (slide.value - 0.55) / 0.4) : 1
            visible: o !== null && slide.value > 0.005 && slide.value < 0.995
            z: 5
            x: o ? o.x + (16 - o.x) * t : 0
            y: o ? o.y + (16 - o.y) * t : 0
            width: o ? o.w + (card.width - 32 - o.w) * t : 0
            height: o ? o.h + (Math.min(card.height - 32, 360) - o.h) * t : 0
            radius: o ? o.radius + (Shape.large - o.radius) * Math.min(1, t) : 0
            color: o ? Qt.tint(o.color, Qt.alpha(Colors.m3surfaceContainer, Math.min(1, t))) : "transparent"
            opacity: fade

            MIcon {
                x: 18 + (44 - 18) * morph.t
                y: (morph.o ? morph.o.h / 2 : 0) - size / 2 + (24 - (morph.o ? morph.o.h / 2 : 0)) * morph.t
                icon: morph.o?.icon ?? ""
                size: 22
                fill: 1
                color: morph.o ? Qt.tint(morph.o.ink, Qt.alpha(Colors.m3onSurface, Math.min(1, morph.t))) : "transparent"
                opacity: 1 - Math.min(1, morph.t * 1.4)
            }
            MText {
                x: 52 + (56 - 52) * morph.t
                y: (morph.o ? morph.o.h / 2 - 10 : 0) + (12 - (morph.o ? morph.o.h / 2 - 10 : 0)) * morph.t
                font.pixelSize: 14 + 8 * Math.min(1, morph.t)
                font.variableAxes: ({ "wght": 600 - 150 * Math.min(1, morph.t) })
                color: morph.o ? Qt.tint(morph.o.ink, Qt.alpha(Colors.m3onSurface, Math.min(1, morph.t))) : "transparent"
                text: morph.o?.label ?? ""
            }
        }

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            Overscroll { flick: flick }

            contentHeight: root.page === "main" ? content.implicitHeight : sub.implicitHeight

            Loader {
                id: sub
                width: parent.width
                active: root.page !== "main" || slide.value > 0.01
                x: root.origin ? 0 : (1 - slide.value) * 48
                opacity: root.origin ? Math.max(0, Math.min(1, slide.value * 2.2 - 1.1)) : slide.value
                visible: opacity > 0.01
                source: ({ audio: "AudioPage.qml", wifi: "WifiPage.qml", bt: "BtPage.qml", privacy: "PrivacyPage.qml" })[root.shownPage] ?? ""
                onLoaded: item.width = Qt.binding(() => sub.width)

                Connections {
                    target: sub.item
                    function onBack() { root.page = "main" }
                }
            }

            Column {
                id: content
                width: parent.width
                spacing: 12
                x: root.origin ? 0 : -slide.value * 48
                opacity: root.origin ? Math.max(0, 1 - slide.value * 1.8) : 1 - slide.value
                scale: root.origin ? 1 - 0.04 * slide.value : 1
                visible: opacity > 0.01

                Item {
                    width: parent.width
                    height: 48

                    Column {
                        anchors.verticalCenter: parent.verticalCenter

                        MText {
                            textStyle: Type.titleLarge
                            text: "Привет, " + Quickshell.env("USER")
                        }

                        MText {
                            visible: root.battery?.isLaptopBattery ?? false
                            textStyle: Type.labelMedium
                            color: Colors.m3onSurfaceVariant
                            text: {
                                const b = root.battery;
                                if (!b) return "";
                                const pct = Math.round((b.percentage > 1 ? b.percentage : b.percentage * 100));
                                if (b.state === UPowerDeviceState.Charging && b.timeToFull > 0)
                                    return pct + "% · до полной " + root.duration(b.timeToFull);
                                if (b.timeToEmpty > 0)
                                    return pct + "% · осталось " + root.duration(b.timeToEmpty);
                                return pct + "%";
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        IconButton {
                            icon: "settings"
                            style: "tonal"
                            onClicked: Panels.openSettings()
                        }

                        IconButton {
                            icon: "wallpaper"
                            style: "tonal"
                            onClicked: Panels.open("wallpaper")
                        }

                        IconButton {
                            icon: "lock"
                            style: "tonal"
                            onClicked: { Panels.close(); Lock.lock(); }
                        }

                        IconButton {
                            icon: "power_settings_new"
                            style: "filled"
                            onClicked: Panels.open("session")
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: sliders.implicitHeight + 24
                    radius: Shape.largeIncreased
                    color: Colors.m3surfaceContainerHigh

                    Column {
                        id: sliders
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 4

                        Row {
                            width: parent.width
                            spacing: 4

                            MSlider {
                                width: parent.width - 48
                                trackHeight: 40
                                icon: Audio.icon
                                value: Audio.muted ? 0 : Audio.volume
                                onMoved: v => Audio.setVolume(v)
                            }

                            IconButton {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "tune"
                                onClicked: root.page = "audio"
                            }
                        }

                        MSlider {
                            width: parent.width
                            visible: Brightness.available
                            trackHeight: 40
                            icon: "brightness_6"
                            value: Brightness.level
                            onMoved: v => Brightness.set(v)
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 8

                    readonly property real cell: (width - spacing) / 2

                    Tile {
                        id: wifiTile
                        width: parent.cell
                        icon: Net.icon
                        label: "Wi-Fi"
                        sublabel: Net.label
                        checked: Net.enabled
                        details: true
                        onDetailsClicked: root.openFrom(wifiTile, "wifi")
                        onClicked: Net.toggle()
                        onSecondaryClicked: root.openFrom(wifiTile, "wifi")
                    }

                    Tile {
                        id: btTile
                        width: parent.cell
                        icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
                        label: "Bluetooth"
                        sublabel: Bt.label
                        checked: Bt.enabled
                        details: true
                        onDetailsClicked: root.openFrom(btTile, "bt")
                        onClicked: Bt.toggle()
                        onSecondaryClicked: root.openFrom(btTile, "bt")
                    }

                    Tile {
                        width: parent.cell
                        icon: "do_not_disturb_on"
                        label: "Не беспокоить"
                        sublabel: Notifs.dnd ? "Включено" : "Выключено"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }

                    Tile {
                        width: parent.cell
                        icon: Power.icon
                        label: "Питание"
                        sublabel: Power.label
                        checked: Power.profile !== PowerProfile.Balanced
                        onClicked: Power.cycle()
                    }

                    Tile {
                        width: parent.cell
                        icon: "coffee"
                        label: "Не засыпать"
                        sublabel: Toggles.caffeine ? "Экран не гаснет" : "Выключено"
                        checked: Toggles.caffeine
                        onClicked: Toggles.caffeine = !Toggles.caffeine
                    }

                    Tile {
                        width: parent.cell
                        icon: "nightlight"
                        label: "Ночной свет"
                        sublabel: Toggles.nightLight ? "Тёплый экран" : "Выключен"
                        checked: Toggles.nightLight
                        onClicked: Toggles.setNightLight(!Toggles.nightLight)
                    }

                    Tile {
                        width: parent.cell
                        icon: Audio.micMuted ? "mic_off" : "mic"
                        label: "Микрофон"
                        sublabel: Audio.micMuted ? "Выключен" : "Включён"
                        checked: !Audio.micMuted
                        onClicked: Audio.toggleMic()
                    }

                    Tile {
                        id: privacyTile
                        width: parent.cell
                        icon: Privacy.active ? "shield_lock" : "shield_person"
                        label: "Приватность"
                        sublabel: Privacy.anyOn ? [Privacy.micOn ? "микрофон" : "", Privacy.camOn ? "камера" : "", Privacy.casting ? "экран" : ""].filter(Boolean).join(", ")
                                : Privacy.active ? "Режим включён" : "Всё тихо"
                        checked: Privacy.active
                        details: true
                        onDetailsClicked: root.openFrom(privacyTile, "privacy")
                        onClicked: Config.o.privacy.mode = !Config.o.privacy.mode
                        onSecondaryClicked: root.openFrom(privacyTile, "privacy")
                    }

                    Tile {
                        id: audioTile
                        width: parent.cell
                        icon: Audio.muted ? "volume_off" : "speaker_group"
                        label: "Звук"
                        sublabel: Audio.label(Audio.sink)
                        checked: false
                        details: true
                        onDetailsClicked: root.openFrom(audioTile, "audio")
                        onClicked: root.openFrom(audioTile, "audio")
                        onSecondaryClicked: root.openFrom(audioTile, "audio")
                    }

                    Tile {
                        width: parent.cell
                        icon: Toggles.dark ? "dark_mode" : "light_mode"
                        label: "Тёмная тема"
                        sublabel: Toggles.dark ? "Включена" : "Выключена"
                        checked: Toggles.dark
                        onClicked: Toggles.toggleDark()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.liveCards.length > 0
                    Repeater {
                        model: ScriptModel { values: root.liveCards; objectProp: "id" }
                        ActivityCard {
                            required property var modelData
                            width: parent.width
                            activity: modelData
                        }
                    }
                }

                MediaCard {
                    width: parent.width
                    visible: Media.player !== null
                    active: root.open
                }

                Item {
                    width: parent.width
                    height: 40

                    FlowText {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 4
                        textStyle: Type.titleMediumEmph
                        text: Notifs.count > 0 ? "Уведомления · " + Notifs.count : "Уведомления"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Notifs.count > 0
                        width: clearLabel.implicitWidth + 28
                        height: 36
                        radius: clearLayer.pressed ? Shape.medium : height / 2
                        color: Colors.m3secondaryContainer

                        Behavior on radius { SpatialAnim { speed: "fast" } }

                        MText {
                            id: clearLabel
                            anchors.centerIn: parent
                            textStyle: Type.labelLarge
                            color: Colors.m3onSecondaryContainer
                            text: "Очистить"
                        }

                        StateLayer {
                            id: clearLayer
                            radius: parent.radius
                            color: Colors.m3onSecondaryContainer
                            onClicked: Notifs.clearAll()
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: Notifs.count > 0

                    Repeater {
                        model: Notifs.list

                        Swipeable {
                            id: sw
                            required property var modelData
                            width: parent.width
                            onDismissed: sw.modelData.dismiss()
                            NotificationCard {
                                width: sw.width
                                height: implicitHeight
                                notif: sw.modelData
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    visible: Notifs.count === 0
                    spacing: 8
                    topPadding: 8
                    bottomPadding: 8

                    MaterialShape {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 72
                        height: 72
                        shape: "cookie7Sided"
                        color: Colors.m3secondaryContainer

                        MIcon {
                            anchors.centerIn: parent
                            icon: "notifications_off"
                            size: 30
                            color: Colors.m3onSecondaryContainer
                        }
                    }

                    MText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        textStyle: Type.bodyMedium
                        color: Colors.m3onSurfaceVariant
                        text: "Всё прочитано"
                    }
                }
            }
        }
    }
}

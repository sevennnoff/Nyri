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
        const pt = tile.mapToItem(flick.contentItem, 0, 0);
        origin = { x: pt.x, y: pt.y, w: tile.width, h: tile.height, radius: tile.checked || !tile.label ? tile.height / 2 : Shape.largeIncreased,
                   color: tile.checked ? Colors.m3primary : tile.label ? Colors.m3surfaceContainerHighest : Colors.m3secondaryContainer,
                   ink: tile.checked ? Colors.m3onPrimary : Colors.m3onSurface, icon: tile.icon, label: tile.label };
        page = pageId;
    }

    function tileOn(id) { return !(Array.isArray(Config.o.control.hidden) && Config.o.control.hidden.indexOf(id) >= 0); }

    readonly property var liveCards: Activities.list.filter(a => a.kind !== "media" && a.kind !== "phone")

    function duration(sec) {
        const total = Math.round(sec / 60), h = Math.floor(total / 60), m = total % 60;
        return h > 0 ? h + " ч " + m + " мин" : m + " мин";
    }

    Popout {
        id: card

        progress: root.progress
        toX: parent.width - toW - 12
        toW: 420
        toH: Math.min((root.page === "main" ? content.implicitHeight : sub.implicitHeight) + 32, room)

        Behavior on toH { SpatialAnim {} }
        defaultFromX: parent.width - 12 - 200
        defaultFromW: 200

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            Overscroll { flick: flick }

            contentHeight: root.page === "main" ? content.implicitHeight : sub.implicitHeight

            Item {
                id: frame
                readonly property var o: root.origin
                readonly property real t: Math.max(0, Math.min(1, slide.value))
                readonly property real tt: Math.max(0, slide.value)
                visible: sub.active && slide.value > 0.005
                x: o ? o.x * (1 - t) : 0
                y: o ? o.y * (1 - t) : 0
                width: o ? o.w + (flick.width - o.w) * tt : flick.width
                height: o ? o.h + (sub.implicitHeight - o.h) * tt : sub.implicitHeight
                clip: o !== null && slide.value < 0.995

                Rectangle {
                    anchors.fill: parent
                    visible: frame.o !== null
                    radius: frame.o ? frame.o.radius + (Shape.large - frame.o.radius) * frame.t : 0
                    color: frame.o ? Qt.tint(frame.o.color, Qt.alpha(Colors.m3surfaceContainer, Math.min(1, frame.t * 1.3))) : "transparent"
                    opacity: 1 - Math.max(0, (slide.value - 0.75) / 0.25)
                }

            Loader {
                id: sub
                width: flick.width
                active: root.page !== "main" || slide.value > 0.01
                x: frame.o ? -frame.x : (1 - slide.value) * 48
                y: frame.o ? -frame.y : 0
                opacity: frame.o ? Math.max(0, Math.min(1, (slide.value - 0.35) / 0.45)) : slide.value
                visible: opacity > 0.01
                source: ({ audio: "AudioPage.qml", wifi: "WifiPage.qml", bt: "BtPage.qml", privacy: "PrivacyPage.qml", phone: "PhonePage.qml" })[root.shownPage] ?? ""
                onLoaded: item.width = Qt.binding(() => sub.width)

                Connections {
                    target: sub.item
                    function onBack() { root.page = "main" }
                }
            }
            }

            Column {
                id: content
                width: parent.width
                spacing: 12
                x: root.origin ? 0 : -slide.value * 48
                opacity: root.origin ? Math.max(0, 1 - slide.value * 1.4) : 1 - slide.value
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
                                id: soundBtn
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "tune"
                                onClicked: root.openFrom(soundBtn, "audio")
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
                        visible: root.tileOn("wifi")
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
                        visible: root.tileOn("bt")
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
                        visible: root.tileOn("dnd")
                        sublabel: Notifs.dnd ? "Включено" : "Выключено"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }

                    Tile {
                        width: parent.cell
                        icon: Power.icon
                        label: "Питание"
                        visible: root.tileOn("power")
                        sublabel: Power.label
                        checked: Power.profile !== PowerProfile.Balanced
                        onClicked: Power.cycle()
                    }

                    Tile {
                        width: parent.cell
                        icon: "coffee"
                        label: "Не засыпать"
                        visible: root.tileOn("caffeine")
                        sublabel: Toggles.caffeine ? "Экран не гаснет" : "Выключено"
                        checked: Toggles.caffeine
                        onClicked: Toggles.caffeine = !Toggles.caffeine
                    }

                    Tile {
                        width: parent.cell
                        icon: "nightlight"
                        label: "Ночной свет"
                        visible: root.tileOn("night")
                        sublabel: Toggles.nightLight ? "Тёплый экран" : "Выключен"
                        checked: Toggles.nightLight
                        onClicked: Toggles.setNightLight(!Toggles.nightLight)
                    }

                    Tile {
                        width: parent.cell
                        icon: Audio.micMuted ? "mic_off" : "mic"
                        label: "Микрофон"
                        visible: root.tileOn("mic")
                        sublabel: Audio.micMuted ? "Выключен" : "Включён"
                        checked: !Audio.micMuted
                        onClicked: Audio.toggleMic()
                    }

                    Tile {
                        id: privacyTile
                        width: parent.cell
                        icon: Privacy.active ? "shield_lock" : "shield_person"
                        label: "Приватность"
                        visible: root.tileOn("privacy")
                        sublabel: Privacy.anyOn ? [Privacy.micOn ? "микрофон" : "", Privacy.camOn ? "камера" : "", Privacy.casting ? "экран" : ""].filter(Boolean).join(", ")
                                : Privacy.active ? "Режим включён" : "Всё тихо"
                        checked: Privacy.active
                        details: true
                        onDetailsClicked: root.openFrom(privacyTile, "privacy")
                        onClicked: Config.o.privacy.mode = !Config.o.privacy.mode
                        onSecondaryClicked: root.openFrom(privacyTile, "privacy")
                    }

                    Tile {
                        width: parent.cell
                        icon: Toggles.dark ? "dark_mode" : "light_mode"
                        label: "Тёмная тема"
                        visible: root.tileOn("dark")
                        sublabel: Toggles.dark ? "Включена" : "Выключена"
                        checked: Toggles.dark
                        onClicked: Toggles.toggleDark()
                    }
                }

                Collapse {
                    width: parent.width
                    shown: root.liveCards.length > 0
                Column {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: ScriptModel { values: root.liveCards; objectProp: "id" }
                        ActivityCard {
                            required property var modelData
                            width: parent.width
                            activity: modelData
                        }
                    }
                }
                }

                Collapse {
                    width: parent.width
                    shown: Media.player !== null
                    MediaCard {
                        width: parent.width
                        active: root.open
                    }
                }

                Collapse {
                    width: parent.width
                    shown: Phone.phone !== null
                    PhoneCard {
                        id: phoneCard
                        width: parent.width
                        onOpened: root.openFrom(phoneCard, "phone")
                    }
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

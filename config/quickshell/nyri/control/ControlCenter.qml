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
    onPageChanged: if (page !== "main") shownPage = page
    onOpenChanged: if (open) page = Panels.tab || "main"
    SpringValue { id: slide; target: root.page === "main" ? 0 : 1; damping: 0.8; stiffness: 480; epsilon: 0.001 }

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

        Flickable {
            anchors.fill: parent
            anchors.margins: 16
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            contentHeight: root.page === "main" ? content.implicitHeight : sub.implicitHeight

            Loader {
                id: sub
                width: parent.width
                active: root.page !== "main" || slide.value > 0.01
                x: (1 - slide.value) * 48
                opacity: slide.value
                visible: opacity > 0.01
                source: root.shownPage === "audio" ? "AudioPage.qml" : root.shownPage === "wifi" ? "WifiPage.qml" : root.shownPage === "bt" ? "BtPage.qml" : ""
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
                x: -slide.value * 48
                opacity: 1 - slide.value
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
                        width: parent.cell
                        icon: Net.icon
                        label: "Wi-Fi"
                        sublabel: Net.label
                        checked: Net.enabled
                        details: true
                        onDetailsClicked: root.page = "wifi"
                        onClicked: Net.toggle()
                        onSecondaryClicked: root.page = "wifi"
                    }

                    Tile {
                        width: parent.cell
                        icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
                        label: "Bluetooth"
                        sublabel: Bt.label
                        checked: Bt.enabled
                        details: true
                        onDetailsClicked: root.page = "bt"
                        onClicked: Bt.toggle()
                        onSecondaryClicked: root.page = "bt"
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
                        width: parent.cell
                        icon: Toggles.dark ? "dark_mode" : "light_mode"
                        label: "Тёмная тема"
                        sublabel: Toggles.dark ? "Включена" : "Выключена"
                        checked: Toggles.dark
                        onClicked: Toggles.toggleDark()
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

                        NotificationCard {
                            required property var modelData
                            width: parent.width
                            height: implicitHeight
                            notif: modelData
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

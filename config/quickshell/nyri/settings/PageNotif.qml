import QtQuick
import Quickshell.Widgets
import Quickshell.Io
import Quickshell
import qs.theme
import qs.services
import qs.widgets

Column {
    spacing: 24

    ListGroup {
        width: parent.width

        SettingRow {
            icon: "do_not_disturb_on"
            title: "Не беспокоить"
            subtitle: "Всплывают только срочные"
            MSwitch { checked: Notifs.dnd; onToggled: c => Notifs.dnd = c }
        }

        SettingRow {
            icon: "timer"
            title: "Сколько висит уведомление"
            subtitle: Config.o.notifications.timeout + " с · срочные висят, пока не закроешь"

            below: MSlider {
                width: parent.width
                value: (Config.o.notifications.timeout - 3) / 12
                onMoved: v => Config.o.notifications.timeout = Math.round(3 + v * 12)
            }
        }

        SettingRow {
            icon: "picture_in_picture"
            title: "Где всплывают"
            choice: Config.o.notifications.position
            choices: [{ value: "left", label: "Слева" }, { value: "center", label: "По центру" }, { value: "right", label: "Справа" }]
            onChosen: v => Config.o.notifications.position = v
        }

        SettingRow {
            icon: "delete_sweep"
            title: "Очистить историю"
            subtitle: Notifs.count > 0 ? Notifs.count + " в центре управления" : "История пуста"
            clickable: Notifs.count > 0
            onClicked: Notifs.clearAll()
        }
    }

    ListGroup {
        width: parent.width
        title: "Шторка и подсказки"

        SettingRow {
            icon: "grid_view"
            title: "Плитки в шторке"
            subtitle: "Нажми, чтобы убрать или вернуть"
            below: Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        { id: "wifi", label: "Wi-Fi" }, { id: "bt", label: "Bluetooth" }, { id: "dnd", label: "Не беспокоить" },
                        { id: "power", label: "Питание" }, { id: "caffeine", label: "Не засыпать" }, { id: "night", label: "Ночной свет" },
                        { id: "mic", label: "Микрофон" }, { id: "privacy", label: "Приватность" },
                        { id: "dark", label: "Тёмная тема" }
                    ]
                    FilterChip {
                        required property var modelData
                        readonly property var hidden: Array.isArray(Config.o.control.hidden) ? Config.o.control.hidden : []
                        text: modelData.label
                        picked: hidden.indexOf(modelData.id) < 0
                        onClicked: Config.o.control.hidden = picked ? hidden.concat([modelData.id]) : hidden.filter(h => h !== modelData.id)
                    }
                }
            }
        }

        SettingRow {
            icon: "volume_up"
            title: "Громкость и яркость"
            subtitle: "Где показывать подсказку при нажатии клавиш"
            choice: Config.o.osd.position
            choices: [{ value: "bar", label: "У панели" }, { value: "opposite", label: "С другой стороны" }, { value: "center", label: "По центру" }]
            onChosen: v => Config.o.osd.position = v
        }
    }
}

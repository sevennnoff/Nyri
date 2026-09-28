import QtQuick
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
            below: SegmentedButtons {
                width: parent.width
                value: Config.o.notifications.position
                options: [{ value: "left", label: "Слева" }, { value: "center", label: "По центру" }, { value: "right", label: "Справа" }]
                onSelected: v => Config.o.notifications.position = v
            }
        }

        SettingRow {
            icon: "delete_sweep"
            title: "Очистить историю"
            subtitle: Notifs.count > 0 ? Notifs.count + " в центре управления" : "История пуста"
            clickable: Notifs.count > 0
            onClicked: Notifs.clearAll()
        }
    }
}

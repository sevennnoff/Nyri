import QtQuick
import Quickshell.Widgets
import Quickshell.Io
import Quickshell
import qs.theme
import qs.services
import qs.widgets

Column {
    id: page
    spacing: 24

    ListGroup {
        width: parent.width
        title: "Экран блокировки"

        SettingRow {
            icon: "schedule"
            title: "Часы"
            subtitle: "Столбиком — огромные, пока не тронешь; строкой — сразу в одну линию"
            choice: Config.o.lock.clock
            choices: [{ value: "stack", label: "Столбиком" }, { value: "row", label: "Строкой" }]
            onChosen: v => Config.o.lock.clock = v
        }
        SettingRow {
            icon: "partly_cloudy_day"
            title: "Погода под часами"
            MSwitch { checked: Config.o.lock.weather; onToggled: c => Config.o.lock.weather = c }
        }
        SettingRow {
            icon: "bubble_chart"
            title: "Что происходит"
            subtitle: "Запись, таймеры, музыка — пилюлями сверху"
            MSwitch { checked: Config.o.lock.live; onToggled: c => Config.o.lock.live = c }
        }
        SettingRow {
            icon: "account_circle"
            title: "Аватар и имя"
            subtitle: "Слева снизу"
            MSwitch { checked: Config.o.lock.user; onToggled: c => Config.o.lock.user = c }
        }
        SettingRow {
            icon: "blur_on"
            title: "Размытые обои"
            MSwitch { checked: Config.o.lock.blur; onToggled: c => Config.o.lock.blur = c }
        }
    }
}

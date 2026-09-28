import QtQuick
import qs.theme
import qs.services
import qs.widgets

Column {
    spacing: 24

    ListGroup {
        width: parent.width
        title: "Поведение"

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
        title: "Что показывать"

        SettingRow {
            icon: "web_asset"
            title: "Активное окно"
            subtitle: "Иконка и заголовок слева"
            MSwitch { checked: Config.o.bar.title; onToggled: c => Config.o.bar.title = c }
        }

        SettingRow {
            icon: "apps"
            title: "Трей"
            subtitle: "Значки фоновых приложений"
            MSwitch { checked: Config.o.bar.tray; onToggled: c => Config.o.bar.tray = c }
        }

        SettingRow {
            icon: "keyboard"
            title: "Раскладка"
            subtitle: "EN / RU рядом со звуком"
            MSwitch { checked: Config.o.bar.layout; onToggled: c => Config.o.bar.layout = c }
        }

        SettingRow {
            icon: "calendar_today"
            title: "Дата у часов"
            MSwitch { checked: Config.o.bar.date; onToggled: c => Config.o.bar.date = c }
        }
    }
}

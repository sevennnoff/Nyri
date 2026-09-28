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
        title: "Док"

        SettingRow {
            icon: "dock_to_bottom"
            title: "Док снизу"
            subtitle: "Закреплённые и открытые приложения. Перетащи иконку вверх — открепится"
            MSwitch { checked: Config.o.dock.enabled; onToggled: c => Config.o.dock.enabled = c }
        }
        SettingRow {
            visible: Config.o.dock.enabled
            icon: "unfold_less"
            title: "Прятать док"
            subtitle: "Появляется у нижнего края и на пустом столе; иначе окна его не заходят"
            MSwitch { checked: Config.o.dock.autohide; onToggled: c => Config.o.dock.autohide = c }
        }
        SettingRow {
            visible: Config.o.dock.enabled
            icon: "zoom_in"
            title: "Увеличение под курсором"
            MSwitch { checked: Config.o.dock.magnify; onToggled: c => Config.o.dock.magnify = c }
        }
        SettingRow {
            visible: Config.o.dock.enabled
            icon: "apps"
            title: "Открытые приложения"
            subtitle: "Показывать и те, что не закреплены"
            MSwitch { checked: Config.o.dock.running; onToggled: c => Config.o.dock.running = c }
        }
        SettingRow {
            visible: Config.o.dock.enabled
            icon: "photo_size_select_large"
            title: "Размер иконок"
            below: Row {
                width: parent.width
                spacing: 12
                MSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    value: (Config.o.dock.size - 36) / 36
                    onMoved: v => Config.o.dock.size = Math.round(36 + v * 36)
                }
                MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLargeEmph; color: Colors.m3primary; text: Config.o.dock.size + " px" }
            }
        }
    }
}

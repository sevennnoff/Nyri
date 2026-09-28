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
        title: "Поиск"

        SettingRow {
            icon: "travel_explore"
            title: "Искать в интернете через"
            choice: Config.o.launcher.engine
            choices: [{ value: "google", label: "Google" }, { value: "ddg", label: "DuckDuckGo" }, { value: "yandex", label: "Яндекс" }, { value: "brave", label: "Brave" }]
            onChosen: v => Config.o.launcher.engine = v
        }

        SettingRow {
            icon: "description"
            title: "Файлы в поиске"
            subtitle: "Из индекса plocate, только домашняя папка"
            MSwitch { checked: Config.o.launcher.files; onToggled: c => Config.o.launcher.files = c }
        }
    }
}

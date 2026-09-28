import QtQuick
import qs.theme
import qs.services
import qs.widgets

Column {
    spacing: 24

    ListGroup {
        width: parent.width

        SettingRow {
            icon: "hourglass_top"
            title: "Считать время в приложениях"
            subtitle: "60 дней"
            MSwitch { checked: Config.o.screenTime.enabled; onToggled: c => Config.o.screenTime.enabled = c }
        }

        SettingRow {
            icon: "bar_chart"
            title: "Открыть статистику"
            clickable: true
            onClicked: Panels.open("power", "usage")
        }

        SettingRow {
            icon: "delete_forever"
            title: "Стереть статистику"
            subtitle: "Нажми дважды"
            clickable: true
            property bool armed: false
            onClicked: {
                if (armed) { ScreenTime.clear(); subtitle = "Стёрто"; armed = false; }
                else { armed = true; subtitle = "Нажми ещё раз, чтобы стереть"; }
            }
        }
    }
}

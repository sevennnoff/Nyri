import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.services
import qs.widgets

Column {
    id: page

    spacing: 24

    function mins(v) {
        return v === 0 ? "никогда" : v + " мин";
    }

    component MinuteRow: SettingRow {
        id: row
        property string key
        property int max: 60
        subtitle: page.mins(Config.o.idle[key])

        below: MSlider {
            width: parent.width
            value: Config.o.idle[row.key] / row.max
            onMoved: v => Config.o.idle[row.key] = Math.round(v * row.max)
        }
    }

    ListGroup {
        width: parent.width
        title: "Профиль"

        SettingRow {
            icon: "speed"
            title: "Режим питания"

            below: SegmentedButtons {
                width: parent.width
                value: Power.profile
                options: [
                    { value: PowerProfile.PowerSaver, label: "Экономия", icon: "eco" },
                    { value: PowerProfile.Balanced, label: "Баланс", icon: "balance" },
                    { value: PowerProfile.Performance, label: "Мощность", icon: "bolt" }
                ]
                onSelected: v => PowerProfiles.profile = v
            }
        }
    }

    ListGroup {
        width: parent.width
        title: "Когда не пользуешься"

        MinuteRow { icon: "monitor"; title: "Гасить экран"; key: "screenOff"; max: 30 }
        MinuteRow { icon: "lock_clock"; title: "Блокировать от сети"; key: "lockAc" }
        MinuteRow { icon: "battery_4_bar"; title: "Блокировать от батареи"; key: "lockBattery" }
        MinuteRow { icon: "bedtime"; title: "Засыпать от батареи"; key: "suspendBattery" }

        SettingRow {
            icon: "login"
            title: "Блокировать при входе"
            subtitle: "Экран блокировки сразу после логина"
            MSwitch { checked: Config.o.idle.lockOnLogin; onToggled: c => Config.o.idle.lockOnLogin = c }
        }
    }

    ListGroup {
        width: parent.width
        title: "Экран блокировки"

        SettingRow {
            icon: "schedule"
            title: "Часы"
            subtitle: "Столбиком — огромные, пока не тронешь; строкой — сразу в одну линию"
            below: SegmentedButtons {
                width: parent.width
                value: Config.o.lock.clock
                options: [{ value: "stack", label: "Столбиком" }, { value: "row", label: "Строкой" }]
                onSelected: v => Config.o.lock.clock = v
            }
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

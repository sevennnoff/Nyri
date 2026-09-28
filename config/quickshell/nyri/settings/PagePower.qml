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
}

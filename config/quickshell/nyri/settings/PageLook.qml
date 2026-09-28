import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Column {
    id: page

    spacing: 24

    readonly property string theme: Paths.bin + "/nyri-theme"

    property var schemes: ({})
    FileView {
        id: schemeCache
        path: Paths.state + "/schemes.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                if (c.wallpaper === Colors.wallpaper && c.mode === Colors.mode) page.schemes = c.schemes;
                else schemeJob.running = true;
            } catch (e) { schemeJob.running = true; }
        }
        onLoadFailed: schemeJob.running = true
    }
    Process {
        id: schemeJob
        command: [page.theme, "--schemes"]
    }

    function apply(env, wall) {
        Quickshell.execDetached(["env", ...env, theme, ...(wall ? [wall] : [])]);
    }

    ListGroup {
        width: parent.width
        title: "Цвета"

        SettingRow {
            icon: "dark_mode"
            title: "Тема"
            subtitle: "Палитра всегда строится из обоев"

            choice: Colors.mode
            choices: [{ value: "dark", label: "Тёмная" }, { value: "light", label: "Светлая" }]
            onChosen: v => Toggles.setMode(v)
        }

        SettingRow {
            icon: "schedule"
            title: "По расписанию"
            subtitle: Config.o.theme.schedule === "off" ? "Тема меняется только вручную"
                    : Config.o.theme.schedule === "sun" ? "Тёмная от заката до рассвета · " + Config.o.weather.city + " · " + Schedule.nextText
                    : "Тёмная с " + Config.o.theme.darkAt + " до " + Config.o.theme.lightAt + " · " + Schedule.nextText

            below: Column {
                width: parent.width
                spacing: 12

                SegmentedButtons {
                    width: parent.width
                    value: Config.o.theme.schedule
                    options: [{ value: "off", label: "Нет" }, { value: "sun", label: "Закат и рассвет" }, { value: "time", label: "По часам" }]
                    onSelected: v => Config.o.theme.schedule = v
                }

                Row {
                    visible: Config.o.theme.schedule === "time"
                    spacing: 16
                    Repeater {
                        model: [{ key: "darkAt", icon: "bedtime", label: "Тёмная" }, { key: "lightAt", icon: "wb_sunny", label: "Светлая" }]
                        Row {
                            id: stepper
                            required property var modelData
                            spacing: 4
                            function shift(d) {
                                const m = Schedule.minutes(Config.o.theme[modelData.key]);
                                const n = (m + d + 1440) % 1440;
                                Config.o.theme[modelData.key] = String(Math.floor(n / 60)).padStart(2, "0") + ":" + String(n % 60).padStart(2, "0");
                            }
                            MIcon { anchors.verticalCenter: parent.verticalCenter; icon: stepper.modelData.icon; size: 20; color: Colors.m3primary }
                            MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLarge; text: stepper.modelData.label }
                            IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "remove"; size: 32; iconSize: 18; onClicked: stepper.shift(-30) }
                            RollingText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.titleMediumEmph; text: Config.o.theme[stepper.modelData.key] }
                            IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "add"; size: 32; iconSize: 18; onClicked: stepper.shift(30) }
                        }
                    }
                }
            }
        }

        SettingRow {
            icon: "wallpaper"
            title: "Обои вместе с темой"
            subtitle: "Сгенерированные обои темнеют и светлеют с темой"
            MSwitch { checked: Config.o.theme.walls; onToggled: c => Config.o.theme.walls = c }
        }

        SettingRow {
            icon: "colors"
            title: "Схема"

            below: Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { id: "scheme-content", label: "Как на обоях" },
                        { id: "scheme-tonal-spot", label: "Спокойная" },
                        { id: "scheme-vibrant", label: "Яркая" },
                        { id: "scheme-expressive", label: "Экспрессивная" },
                        { id: "scheme-fidelity", label: "Точная" },
                        { id: "scheme-fruit-salad", label: "Фруктовая" },
                        { id: "scheme-rainbow", label: "Радуга" },
                        { id: "scheme-neutral", label: "Нейтральная" },
                        { id: "scheme-monochrome", label: "Монохром" }
                    ]

                    FilterChip {
                        required property var modelData
                        text: modelData.label
                        picked: Colors.scheme === modelData.id
                        swatch: page.schemes[modelData.id] ?? null
                        onClicked: page.apply(["NYRI_SCHEME=" + modelData.id])
                    }
                }
            }
        }
    }

    ListGroup {
        width: parent.width
        title: "Ночной свет"

        SettingRow {
            icon: "nightlight"
            title: "Режим"
            subtitle: Config.o.night.mode === "auto" ? "Тёплый экран от заката до рассвета · " + Config.o.weather.city
                    : Config.o.night.mode === "on" ? "Тёплый экран весь день" : "Выключен"

            choice: Config.o.night.mode
            choices: [{ value: "off", label: "Выкл" }, { value: "on", label: "Всегда" }, { value: "auto", label: "По закату" }]
            onChosen: v => Config.o.night.mode = v
        }

        SettingRow {
            icon: "thermostat"
            title: "Теплота"
            subtitle: Config.o.night.temp + " K"
            visible: Config.o.night.mode !== "off"

            below: MSlider {
                width: parent.width
                value: (5000 - Config.o.night.temp) / 2500
                onMoved: v => Config.o.night.temp = Math.round((5000 - v * 2500) / 100) * 100
            }
        }
    }

    ListGroup {
        width: parent.width
        title: "Движение"

        SettingRow {
            icon: "animation"
            title: "Скорость анимаций"
            subtitle: Config.o.motion.speed < 0.9 ? "Медленнее, чтобы рассмотреть" : Config.o.motion.speed > 1.1 ? "Быстрее" : "Как задумано"

            choice: Config.o.motion.speed
            choices: [{ value: 0.7, label: "Медленнее" }, { value: 1.0, label: "Обычно" }, { value: 1.4, label: "Быстрее" }]
            onChosen: v => Config.o.motion.speed = v
        }
    }
}

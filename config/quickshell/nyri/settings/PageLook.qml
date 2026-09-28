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

            below: SegmentedButtons {
                width: parent.width
                value: Colors.mode
                options: [{ value: "dark", label: "Тёмная" }, { value: "light", label: "Светлая" }]
                onSelected: v => page.apply(["NYRI_MODE=" + v])
            }
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
            visible: Config.o.theme.schedule !== "off"
            icon: "wallpaper"
            title: "Ночные обои"
            subtitle: "Сгенерированные обои на ночь перерисовываются в тёмной палитре из своего же акцента"
            MSwitch { checked: Config.o.theme.walls; onToggled: c => Config.o.theme.walls = c }
        }

        SettingRow {
            icon: "colors"
            title: "Схема"
            subtitle: "Как matugen раскрашивает обои"

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
        title: "Рабочий стол"

        SettingRow {
            icon: "widgets"
            title: "Виджеты на обоях"
            subtitle: "Перетаскивайте мышью; правый клик по виджету — другой вид"
            MSwitch { checked: Config.o.desktop.enabled; onToggled: c => Config.o.desktop.enabled = c }
        }

        SettingRow {
            icon: "grid_4x4"
            title: "Прилипать к сетке"
            subtitle: "Виджет встаёт в ближайшую ячейку, пока тащите — видна сетка"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.grid; onToggled: c => Config.o.desktop.grid = c }

            below: SegmentedButtons {
                width: parent.width
                value: Config.o.desktop.gridSize
                options: [{ value: 16, label: "Мелкая" }, { value: 24, label: "Средняя" }, { value: 48, label: "Крупная" }]
                onSelected: v => Config.o.desktop.gridSize = v
            }
        }

        SettingRow {
            icon: "dashboard_customize"
            title: "Изменить рабочий стол"
            subtitle: "Добавить и убрать виджеты, двигать, менять размер; Esc — готово"
            enabled: Config.o.desktop.enabled
            clickable: true
            onClicked: { Panels.settingsOpen = false; Panels.deskEdit = true; }
        }

        SettingRow {
            icon: "restart_alt"
            title: "Вернуть виджеты на место"
            subtitle: "Столбиком слева, как было, обычного размера и на всех столах"
            enabled: Config.o.desktop.enabled
            clickable: true
            onClicked: { Config.o.desktop.positions = ({}); Config.o.desktop.scales = ({}); Config.o.desktop.only = ({}); }
        }

        SettingRow {
            icon: "schedule"
            title: "Часы"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.clock; onToggled: c => Config.o.desktop.clock = c }
        }

        SettingRow {
            icon: "today"
            title: "Дата и погода"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.glance; onToggled: c => Config.o.desktop.glance = c }
        }

        SettingRow {
            icon: "battery_full"
            title: "Батарея"
            subtitle: "Заряд и сколько ещё протянет"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.battery; onToggled: c => Config.o.desktop.battery = c }
        }

        SettingRow {
            icon: "music_note"
            title: "Плеер"
            subtitle: "Появляется, когда что-то играет"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.media; onToggled: c => Config.o.desktop.media = c }
        }

        SettingRow {
            icon: "partly_cloudy_day"
            title: "Прогноз"
            subtitle: "Пять дней или погода прямо сейчас"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.forecast; onToggled: c => Config.o.desktop.forecast = c }
        }

        SettingRow {
            icon: "calendar_month"
            title: "Календарь"
            subtitle: "Месяц или неделя"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.calendar; onToggled: c => Config.o.desktop.calendar = c }
        }

        SettingRow {
            icon: "memory"
            title: "Система"
            subtitle: "Процессор, память, диск; считается только пока стол виден"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.system; onToggled: c => Config.o.desktop.system = c }
        }

        SettingRow {
            icon: "hourglass_top"
            title: "Экранное время"
            subtitle: "Сегодня: всего и самые частые приложения"
            enabled: Config.o.desktop.enabled
            MSwitch { checked: Config.o.desktop.usage; onToggled: c => Config.o.desktop.usage = c }
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

            below: SegmentedButtons {
                width: parent.width
                value: Config.o.night.mode
                options: [{ value: "off", label: "Выкл" }, { value: "on", label: "Всегда" }, { value: "auto", label: "По закату" }]
                onSelected: v => Config.o.night.mode = v
            }
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

            below: SegmentedButtons {
                width: parent.width
                value: Config.o.motion.speed
                options: [{ value: 0.7, label: "Медленнее" }, { value: 1.0, label: "Обычно" }, { value: 1.4, label: "Быстрее" }]
                onSelected: v => Config.o.motion.speed = v
            }
        }
    }

    ListGroup {
        width: parent.width
        title: "Погода"

        SettingRow {
            id: cityRow
            icon: "location_on"
            title: "Город"
            subtitle: Config.o.weather.city + " · " + Config.o.weather.lat.toFixed(2) + ", " + Config.o.weather.lon.toFixed(2)

            below: Row {
                width: parent.width
                spacing: 8

                SearchField {
                    id: city
                    width: parent.width - 56
                    icon: "search"
                    placeholder: "Найти город"
                    input.onAccepted: find.clicked()
                }

                IconButton {
                    id: find
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "arrow_forward"
                    style: "filled"
                    size: 48
                    onClicked: if (city.text.trim()) geo.lookup(city.text.trim())
                }
            }

            Process {
                id: geo
                function lookup(name) {
                    command = ["curl", "-s", "--max-time", "10", "https://geocoding-api.open-meteo.com/v1/search?count=1&language=ru&name=" + encodeURIComponent(name)];
                    running = true;
                }
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const r = JSON.parse(text).results?.[0];
                            if (!r) { cityRow.subtitle = "Не нашёл такой город"; return; }
                            Config.o.weather.city = r.name;
                            Config.o.weather.lat = r.latitude;
                            Config.o.weather.lon = r.longitude;
                            city.text = "";
                            Weather.refresh();
                        } catch (e) {}
                    }
                }
            }
        }
    }

    ListGroup {
        width: parent.width
        title: "Обои"

        SettingRow {
            id: wallRow
            icon: "wallpaper"
            title: "Студия обоев"
            subtitle: "20 стилей, 33 палитры и свой цвет, сетка · Mod+Y"
            clickable: true
            onClicked: Panels.open("wallpaper")

            MIcon { icon: "chevron_right"; color: Colors.m3onSurfaceVariant }

            below: ClippingRectangle {
                width: parent.width
                height: width * 0.5
                radius: Shape.large
                color: Colors.m3surfaceContainerHighest

                Image {
                    anchors.fill: parent
                    source: Colors.wallpaper ? "file://" + Colors.wallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(width * 2, height * 2)
                    asynchronous: true
                }
            }
        }

        SettingRow {
            icon: "desktop_windows"
            title: "Единые обои на все экраны"
            subtitle: Quickshell.screens.length > 1 ? "Одна картинка через все мониторы, как они стоят" : "Пригодится, когда подключён второй монитор"
            MSwitch { checked: Config.o.wallpaper.span; onToggled: c => Config.o.wallpaper.span = c }
        }
    }

    ListGroup {
        width: parent.width
        title: "Поиск"

        SettingRow {
            icon: "travel_explore"
            title: "Искать в интернете через"
            below: SegmentedButtons {
                width: parent.width
                value: Config.o.launcher.engine
                options: [{ value: "google", label: "Google" }, { value: "ddg", label: "DuckDuckGo" }, { value: "yandex", label: "Яндекс" }, { value: "brave", label: "Brave" }]
                onSelected: v => Config.o.launcher.engine = v
            }
        }

        SettingRow {
            icon: "description"
            title: "Файлы в поиске"
            subtitle: "Из индекса plocate, только домашняя папка"
            MSwitch { checked: Config.o.launcher.files; onToggled: c => Config.o.launcher.files = c }
        }
    }
}

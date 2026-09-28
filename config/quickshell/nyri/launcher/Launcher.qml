import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Surface {
    id: root

    name: "launcher"

    readonly property string query: field.text
    property string filter: "all"
    readonly property var filters: [
        { id: "all", label: "Всё", icon: "apps" },
        { id: "app", label: "Приложения", icon: "grid_view" },
        { id: "window", label: "Окна", icon: "select_window" },
        { id: "file", label: "Файлы", icon: "description" },
        { id: "action", label: "Действия", icon: "bolt" }
    ]
    function wants(kind) {
        if (filter === "all") return true;
        if (filter === "action") return kind === "action" || kind === "setting" || kind === "timer" || kind === "appaction";
        return kind === filter;
    }
    readonly property var engines: ({
        google: { name: "Google", url: "https://www.google.com/search?q=" },
        ddg: { name: "DuckDuckGo", url: "https://duckduckgo.com/?q=" },
        yandex: { name: "Яндекс", url: "https://yandex.ru/search/?text=" },
        brave: { name: "Brave", url: "https://search.brave.com/search?q=" }
    })
    readonly property var engine: engines[Config.o.launcher.engine] ?? engines.google

    readonly property var settingsIndex: [
        { page: "look", label: "Оформление", keys: ["тема", "цвет", "схема", "обои", "виджет", "ночной", "анимац", "расписан", "масштаб"] },
        { page: "bar", label: "Панель", keys: ["панель", "бар", "bar", "остров", "часы", "трей", "секунд", "раскладк"] },
        { page: "notif", label: "Уведомления", keys: ["уведомл", "notif", "всплыв"] },
        { page: "power", label: "Питание и сон", keys: ["питан", "сон", "блокир", "экран гаснет", "батар"] },
        { page: "usage", label: "Экранное время", keys: ["экранн", "время", "статист"] },
        { page: "about", label: "О системе", keys: ["систем", "версия", "about"] }
    ]
    readonly property string mode: query.startsWith("=") ? "calc" : query.startsWith(">") ? "run" : "apps"
    readonly property var results: {
        if (mode !== "apps")
            return [];
        const q = query.trim().toLowerCase();
        if (!q) {
            if (filter === "window") return Object.values(Niri.windows).map(w => ({ kind: "window", win: w }));
            return filter === "all" || filter === "app" ? Apps.search("").map(e => ({ kind: "app", entry: e })) : [];
        }
        const answer = root.looksLikeMath && root.calcResult && filter === "all" ? [{ kind: "calc", text: root.calcResult }] : [];
        const tm = query.trim().match(/^(таймер|timer|засеки)\s+(\S+(?:\s*(?:ч|час\S*|м|мин\S*|с|сек\S*|h|m|s|min)\b)?)\s*(.*)$/i);
        const secs = tm ? Activities.parseDuration(tm[2]) : 0;
        if (secs > 0 && wants("timer"))
            answer.push({ kind: "timer", secs, label: tm[3] ?? "", text: "Таймер на " + Activities.fmtDuration(secs * 1000) + (tm[3] ? " · " + tm[3] : "") });

        const scored = [];
        for (const w of Object.values(Niri.windows)) {
            const t = (w.title ?? "").toLowerCase(), id = (w.app_id ?? "").toLowerCase();
            const sc = t.startsWith(q) || id.startsWith(q) ? 92 : t.includes(q) || id.includes(q) ? 75 : 0;
            if (sc) scored.push({ kind: "window", win: w, score: sc });
        }
        for (const e of Apps.all) {
            const sc = Apps.score(e, q);
            if (sc) scored.push({ kind: "app", entry: e, score: sc + Apps.frecency(e) * 6 });
        }
        for (const a of actions) {
            const sc = a.keys.some(k => k.startsWith(q)) ? 96 : a.keys.some(k => k.includes(q)) ? 70 : 0;
            if (sc) scored.push({ kind: "action", action: a, score: sc });
        }
        for (const p of settingsIndex) {
            const sc = p.label.toLowerCase().startsWith(q) ? 72 : p.keys.some(k => k.startsWith(q) || q.startsWith(k)) ? 58 : 0;
            if (sc) scored.push({ kind: "setting", page: p, score: sc });
        }
        const topApps = scored.filter(x => x.kind === "app").sort((x, y) => y.score - x.score).slice(0, 2);
        for (const t of topApps)
            for (const act of (t.entry.actions ?? []).slice(0, 3))
                scored.push({ kind: "appaction", entry: t.entry, act, score: t.score - 12 });
        for (const f of fileHits)
            scored.push({ kind: "file", path: f, score: 50 });
        const kept = scored.filter(x => wants(x.kind));
        kept.sort((x, y) => y.score - x.score);
        if (filter === "all") kept.push({ kind: "web", text: query.trim() });
        return answer.concat(kept);
    }

    readonly property var actions: [
        { label: "Настройки", icon: "settings", keys: ["настройки", "settings", "параметры"], run: () => Panels.openSettings() },
        { label: "Заблокировать", icon: "lock", keys: ["блок", "заблокировать", "lock"], run: () => Lock.lock() },
        { label: "Меню питания", icon: "power_settings_new", keys: ["выключ", "перезагр", "сон", "выйти", "power", "reboot", "shutdown", "logout", "sleep"], run: () => Panels.open("session") },
        { label: "Обои", icon: "wallpaper", keys: ["обои", "wallpaper"], run: () => Panels.open("wallpaper") },
        { label: "Найти телефон", icon: "ring_volume", keys: ["телефон", "найти телефон", "phone", "ring"], run: () => Phone.ring() },
        { label: "Отправить буфер на телефон", icon: "content_paste_go", keys: ["телефон", "буфер на телефон", "phone clipboard"], run: () => Phone.sendClipboard() },
        { label: "Телефон", icon: "smartphone", keys: ["телефон", "phone", "kde connect"], run: () => Panels.open("control", "phone") },
        { label: "Изменить рабочий стол", icon: "dashboard_customize", keys: ["виджет", "стол", "рабочий", "widget", "desk", "edit"], run: () => Panels.deskEdit = true },
        { label: "Буфер обмена", icon: "content_paste", keys: ["буфер", "clipboard", "история"], run: () => Panels.open("clipboard") },
        { label: "Центр управления", icon: "tune", keys: ["центр", "шторка", "панель", "control"], run: () => Panels.open("control") },
        { label: Toggles.dark ? "Светлая тема" : "Тёмная тема", icon: Toggles.dark ? "light_mode" : "dark_mode", keys: ["тема", "тёмн", "темн", "светл", "theme", "dark", "light"], run: () => Toggles.toggleDark() },
        { label: Notifs.dnd ? "Выключить «Не беспокоить»" : "Не беспокоить", icon: "do_not_disturb_on", keys: ["не беспок", "dnd", "тихо"], run: () => Notifs.dnd = !Notifs.dnd },
        { label: "Не засыпать", icon: "coffee", keys: ["засып", "кофе", "caffeine", "awake"], run: () => Toggles.caffeine = !Toggles.caffeine },
        { label: "Пипетка", icon: "colorize", keys: ["пипетк", "цвет", "color", "picker"], run: () => Quickshell.execDetached([Paths.bin + "/nyri", "picker"]) },
        { label: "Экранное время", icon: "hourglass_top", keys: ["время", "экранн", "screen time", "статист"], run: () => Panels.open("power", "usage") },
        { label: "Батарея", icon: "battery_full", keys: ["батар", "заряд", "battery"], run: () => Panels.open("power", "battery") }
    ]
    property string calcResult: ""

    property var fileHits: []
    Process {
        id: locate
        stdout: StdioCollector {
            onStreamFinished: {
                const home = Quickshell.env("HOME") + "/";
                root.fileHits = text.split("\n").filter(p => p.startsWith(home) && !/\/\.[^/]/.test(p.slice(home.length))).slice(0, 8);
            }
        }
    }
    Timer {
        id: locateDebounce
        interval: 200
        onTriggered: {
            const q = root.query.trim();
            if (!Config.o.launcher.files || q.length < 3 || root.mode !== "apps" || (root.filter !== "all" && root.filter !== "file")) { root.fileHits = []; return; }
            locate.command = ["plocate", "-i", "-b", "-l", "60", q];
            locate.running = true;
        }
    }

    readonly property bool looksLikeMath: {
        const q = query.trim();
        return /\d/.test(q) && (/[-+*\/^%×÷()=]/.test(q) || /(^|\s)(to|in|в|во)\s/i.test(q)
            || /(usd|eur|rub|cny|gbp|kzt|uah|руб|доллар|бакс|евро|юан|фунт|тенге|гривн|km|км|kg|кг|mi|миль|°|mb|gb|мб|гб)/i.test(q));
    }

    function expression(q) {
        return q
            .replace(/(\d+(?:[.,]\d+)?)\s*%\s*(от|of)\s+/gi, "($1/100)*")
            .replace(/(^|\s)(в|во|in)(\s)/gi, " to ")
            .replace(/руб\S*|₽/gi, "RUB").replace(/(доллар|бакс)\S*|\$/gi, "USD").replace(/евро|€/gi, "EUR")
            .replace(/юан\S*/gi, "CNY").replace(/фунт\S*/gi, "GBP").replace(/тенге/gi, "KZT").replace(/гривн\S*/gi, "UAH")
            .replace(/(\d)\s*км\b|(\s)км\b/gi, "$1$2 km").replace(/(\d)\s*кг\b|(\s)кг\b/gi, "$1$2 kg")
            .replace(/мил[ьяи]\S*/gi, "mi").replace(/мб\b/gi, "MB").replace(/гб\b/gi, "GB");
    }
    readonly property bool currency: /RUB|USD|EUR|CNY|GBP|KZT|UAH/i.test(expression(query))
    property bool ratesFresh: false

    property bool cascade: false
    Timer { id: cascadeOff; interval: 450; onTriggered: root.cascade = false }

    onOpenChanged: {
        if (open) {
            cascade = true;
            cascadeOff.restart();
            field.text = "";
            filter = "all";
            fileHits = [];
            list.currentIndex = 0;
            field.input.forceActiveFocus();
        }
    }

    function accept(shift) {
        if (mode === "apps" && results[list.currentIndex]?.kind === "calc") {
            Quickshell.execDetached(["wl-copy", calcResult]);
        } else if (mode === "calc") {
            if (calcResult)
                Quickshell.execDetached(["wl-copy", calcResult]);
        } else if (mode === "run") {
            const cmd = query.slice(1).trim();
            if (cmd)
                Quickshell.execDetached(shift ? ["kitty", "-e", "sh", "-c", cmd] : ["sh", "-c", cmd]);
        } else if (results[list.currentIndex]) {
            const r = results[list.currentIndex];
            Panels.close();
            if (r.kind === "app") Apps.launch(r.entry);
            else if (r.kind === "window") Niri.action("focus-window", "--id", String(r.win.id));
            else if (r.kind === "action") r.action.run();
            else if (r.kind === "setting") Panels.openSettings(r.page.page);
            else if (r.kind === "timer") Activities.addTimer(r.secs, r.label);
            else if (r.kind === "appaction") r.act.execute();
            else if (r.kind === "file") Qt.openUrlExternally("file://" + r.path);
            else if (r.kind === "web") Qt.openUrlExternally(root.engine.url + encodeURIComponent(r.text));
            return;
        }
        Panels.close();
    }

    Process {
        id: qalc
        property string asked: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.calcResult = t && /\d/.test(t) && t !== qalc.asked.trim() ? t : "";
            }
        }
    }

    Timer {
        id: calcDebounce
        interval: 150
        onTriggered: {
            const expr = root.mode === "calc" ? root.query.slice(1) : root.expression(root.query.trim());
            if (!expr.trim()) return;
            const update = root.currency && !root.ratesFresh;
            if (update) root.ratesFresh = true;
            qalc.asked = expr;
            qalc.command = ["qalc", "-t", "-set", "conv 0", ...(update ? ["-e"] : []), expr];
            qalc.running = true;
        }
    }

    onQueryChanged: {
        list.currentIndex = 0;
        locateDebounce.restart();
        if (mode === "calc" || (mode === "apps" && looksLikeMath)) calcDebounce.restart();
        else calcResult = "";
    }

    Popout {
        id: card

        progress: root.progress
        toX: (parent.width - toW) / 2
        toW: 640
        toH: content.implicitHeight + 24
        defaultFromX: 12
        defaultFromW: 40

        Behavior on toH { SpatialAnim {} }

        Column {
            id: content
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 8

            SearchField {
                id: field
                width: parent.width
                icon: root.mode === "calc" ? "calculate" : root.mode === "run" ? "terminal" : "search"
                placeholder: "Приложения, файлы, настройки, 2+2, таймер 5м · > команда"

                input.Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        const i = root.filters.findIndex(f => f.id === root.filter);
                        const n = root.filters.length;
                        root.filter = root.filters[(i + (event.key === Qt.Key_Tab ? 1 : n - 1)) % n].id;
                        list.currentIndex = 0;
                        locateDebounce.restart();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                        list.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                        list.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.accept(event.modifiers & Qt.ShiftModifier);
                        event.accepted = true;
                    }
                }
            }

            Row {
                visible: root.mode === "apps"
                spacing: 8
                Repeater {
                    model: root.filters
                    FilterChip {
                        required property var modelData
                        text: modelData.label
                        picked: root.filter === modelData.id
                        onClicked: { root.filter = modelData.id; list.currentIndex = 0; locateDebounce.restart(); field.input.forceActiveFocus(); }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 72
                radius: Shape.largeIncreased
                visible: root.mode !== "apps"
                color: Colors.m3secondaryContainer

                MText {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 20
                    width: parent.width - 40
                    elide: Text.ElideRight
                    textStyle: root.mode === "calc" ? Type.headlineSmall : Type.titleMedium
                    color: Colors.m3onSecondaryContainer
                    text: root.mode === "calc"
                        ? (root.calcResult || "…")
                        : "Выполнить: " + (root.query.slice(1).trim() || "…")
                }
            }

            ListView {
                id: list
                width: parent.width
                height: Math.min(count, 8) * 56
                visible: root.mode === "apps"
                model: root.results
                clip: true
                Overscroll { flick: list; step: 0.47 }
                highlightMoveDuration: 0
                highlightFollowsCurrentItem: false

                populate: Transition {
                    id: pop
                    enabled: root.cascade
                    SequentialAnimation {
                        PauseAnimation { duration: pop.ViewTransition.index * 28 }
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.effects.duration }
                            NumberAnimation { property: "x"; from: 32; to: 0; duration: Motion.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.fastSpatial.curve }
                        }
                    }
                }

                highlight: Rectangle {
                    width: list.width
                    height: 56
                    y: hl.value
                    radius: Shape.largeIncreased
                    color: Colors.m3secondaryContainer

                    SpringValue { id: hl; target: list.currentItem?.y ?? 0; damping: 0.72; stiffness: 700; epsilon: 0.1 }
                }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property var entry: modelData.kind === "app" || modelData.kind === "appaction" ? modelData.entry
                        : modelData.kind === "window" ? DesktopEntries.heuristicLookup(modelData.win.app_id) : null
                    readonly property string title: modelData.kind === "calc" ? modelData.text
                        : modelData.kind === "app" ? entry.name
                        : modelData.kind === "window" ? (modelData.win.title || entry?.name || modelData.win.app_id)
                        : modelData.kind === "action" ? modelData.action.label
                        : modelData.kind === "setting" ? modelData.page.label
                        : modelData.kind === "timer" ? modelData.text
                        : modelData.kind === "appaction" ? modelData.act.name
                        : modelData.kind === "file" ? modelData.path.split("/").pop()
                        : "Найти в интернете: " + modelData.text
                    readonly property string subtitle: modelData.kind === "calc" ? "= " + root.query.trim() + " · Enter — скопировать"
                        : modelData.kind === "app" ? (entry.genericName || entry.comment || "")
                        : modelData.kind === "window" ? "Открытое окно · " + (entry?.name ?? modelData.win.app_id)
                        : modelData.kind === "action" ? "Действие"
                        : modelData.kind === "setting" ? "Настройки"
                        : modelData.kind === "timer" ? "Enter — запустить"
                        : modelData.kind === "appaction" ? (entry?.name ?? "")
                        : modelData.kind === "file" ? modelData.path.replace(Quickshell.env("HOME"), "~").replace(/\/[^/]*$/, "")
                        : root.engine.name
                    readonly property string symbol: modelData.kind === "calc" ? (root.currency ? "currency_exchange" : "calculate")
                        : modelData.kind === "action" ? modelData.action.icon
                        : modelData.kind === "setting" ? "settings"
                        : modelData.kind === "timer" ? "timer"
                        : modelData.kind === "file" ? (/\.(png|jpe?g|webp|gif|svg)$/i.test(modelData.path) ? "image" : /\.(mp4|mkv|webm|mov)$/i.test(modelData.path) ? "movie" : /\.(mp3|flac|ogg|wav|m4a)$/i.test(modelData.path) ? "music_note" : /\.(pdf|docx?|odt|txt|md)$/i.test(modelData.path) ? "description" : "draft")
                        : modelData.kind === "web" ? "travel_explore" : ""

                    width: list.width
                    height: 56

                    Item {
                        id: iconBox
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        width: 36
                        height: 36

                        IconImage {
                            anchors.fill: parent
                            visible: row.symbol === ""
                            source: row.symbol === "" ? Quickshell.iconPath(row.modelData.kind === "window" ? Apps.iconFor(row.modelData.win.app_id) : (row.entry?.icon ?? ""), "application-x-executable") : ""
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: row.symbol !== ""
                            radius: 18
                            color: row.current ? Colors.m3primary : Colors.m3surfaceContainerHighest

                            MIcon {
                                anchors.centerIn: parent
                                icon: row.symbol
                                size: 20
                                fill: 1
                                color: row.current ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            }
                        }

                        Rectangle {
                            visible: row.modelData.kind === "window"
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: -3
                            width: 18
                            height: 18
                            radius: 9
                            color: Colors.m3primary

                            MIcon {
                                anchors.centerIn: parent
                                icon: "open_in_new"
                                size: 12
                                color: Colors.m3onPrimary
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: iconBox.right
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 16

                        MText {
                            width: parent.width
                            elide: Text.ElideRight
                            textStyle: row.current ? Type.titleMediumEmph : Type.titleMedium
                            color: row.current ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                            text: row.title
                        }

                        MText {
                            width: parent.width
                            visible: text !== ""
                            elide: Text.ElideRight
                            textStyle: Type.labelMedium
                            color: row.current ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                            text: row.subtitle
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: root.accept(false)
                    }
                }
            }

            MText {
                visible: root.mode === "apps" && list.count === 0
                width: parent.width
                height: 56
                horizontalAlignment: Text.AlignHCenter
                textStyle: Type.bodyMedium
                color: Colors.m3onSurfaceVariant
                text: "Ничего не нашлось"
            }
        }
    }
}

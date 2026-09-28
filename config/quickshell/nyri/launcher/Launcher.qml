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
    readonly property string mode: query.startsWith("=") ? "calc" : query.startsWith(">") ? "run" : "apps"
    readonly property var results: {
        if (mode !== "apps")
            return [];
        const q = query.trim().toLowerCase();
        if (!q)
            return Apps.search("").map(e => ({ kind: "app", entry: e }));
        const answer = root.looksLikeMath && root.calcResult ? [{ kind: "calc", text: root.calcResult }] : [];

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
        scored.sort((x, y) => y.score - x.score);
        scored.push({ kind: "web", text: query.trim() });
        return answer.concat(scored);
    }

    readonly property var actions: [
        { label: "Настройки", icon: "settings", keys: ["настройки", "settings", "параметры"], run: () => Panels.openSettings() },
        { label: "Заблокировать", icon: "lock", keys: ["блок", "заблокировать", "lock"], run: () => Lock.lock() },
        { label: "Меню питания", icon: "power_settings_new", keys: ["выключ", "перезагр", "сон", "выйти", "power", "reboot", "shutdown", "logout", "sleep"], run: () => Panels.open("session") },
        { label: "Обои", icon: "wallpaper", keys: ["обои", "wallpaper"], run: () => Panels.open("wallpaper") },
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
            else if (r.kind === "web") Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(r.text));
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
                placeholder: "Приложения, окна, действия, 2+2, 100 usd в руб · > команда"

                input.Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && event.key === Qt.Key_J)) {
                        list.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
                        list.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.accept(event.modifiers & Qt.ShiftModifier);
                        event.accepted = true;
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
                boundsBehavior: Flickable.StopAtBounds
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
                    readonly property var entry: modelData.kind === "app" ? modelData.entry
                        : modelData.kind === "window" ? DesktopEntries.heuristicLookup(modelData.win.app_id) : null
                    readonly property string title: modelData.kind === "calc" ? modelData.text
                        : modelData.kind === "app" ? entry.name
                        : modelData.kind === "window" ? (modelData.win.title || entry?.name || modelData.win.app_id)
                        : modelData.kind === "action" ? modelData.action.label
                        : "Найти в интернете: " + modelData.text
                    readonly property string subtitle: modelData.kind === "calc" ? "= " + root.query.trim() + " · Enter — скопировать"
                        : modelData.kind === "app" ? (entry.genericName || entry.comment || "")
                        : modelData.kind === "window" ? "Открытое окно · " + (entry?.name ?? modelData.win.app_id)
                        : modelData.kind === "action" ? "Действие"
                        : "Google"
                    readonly property string symbol: modelData.kind === "calc" ? (root.currency ? "currency_exchange" : "calculate")
                        : modelData.kind === "action" ? modelData.action.icon
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

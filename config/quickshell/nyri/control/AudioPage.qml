import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Column {
    id: root

    signal back
    spacing: 16

    PwObjectTracker { objects: [...Audio.sinks, ...Audio.sources, ...Audio.streams] }

    PageHeader {
        title: "Звук"
        onBack: root.back()
    }

    property var cards: []
    property var streamSink: ({})
    Component.onCompleted: refresh()
    readonly property int streamCount: Audio.streams.length
    onStreamCountChanged: refresh()
    function refresh() { if (!cardsProc.running) cardsProc.running = true; if (!inputsProc.running) inputsProc.running = true; }
    Process {
        id: cardsProc
        command: ["pactl", "-f", "json", "list", "cards"]
        stdout: StdioCollector { onStreamFinished: { try { root.cards = JSON.parse(text); } catch (e) {} } }
    }
    Process {
        id: inputsProc
        command: ["sh", "-c", "pactl -f json list sink-inputs; echo; pactl -f json list sinks"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\n");
                try {
                    const inputs = JSON.parse(parts[0]), sinks = JSON.parse(parts[1] ?? "[]");
                    const byIndex = {};
                    for (const s of sinks) byIndex[s.index] = s.name;
                    const map = {};
                    for (const i of inputs) map[i.properties["object.id"]] = byIndex[i.sink];
                    root.streamSink = map;
                } catch (e) {}
            }
        }
    }
    function moveStream(node, sink) {
        const sh = "i=$(pactl -f json list sink-inputs | jq -r '.[] | select(.properties[\"object.id\"]==\"" + node.id + "\") | .index'); "
                 + "[ -n \"$i\" ] && pactl move-sink-input \"$i\" '" + (sink.name ?? "").replace(/'/g, "") + "'";
        Quickshell.execDetached(["sh", "-c", sh]);
        const next = Object.assign({}, streamSink);
        next[String(node.id)] = sink.name;
        streamSink = next;
    }
    function cardOf(node) {
        const addr = node.properties["api.bluez5.address"];
        if (addr) return cards.find(c => c.name === "bluez_card." + addr.replace(/:/g, "_")) ?? null;
        const dev = node.properties["device.name"] ?? "";
        return cards.find(c => c.name === dev) ?? null;
    }
    function setProfile(card, profile) {
        if (!card) return;
        Quickshell.execDetached(["pactl", "set-card-profile", card.name, profile]);
        refreshLater.restart();
    }
    Timer { id: refreshLater; interval: 1200; onTriggered: root.refresh() }

    readonly property var btSinks: Audio.sinks.filter(n => (n.name ?? "").startsWith("bluez"))
    function btDevice(node) {
        const a = (node.properties["api.bluez5.address"] ?? "").toUpperCase();
        return a ? Bt.connected.find(d => (d.address ?? "").toUpperCase() === a) ?? null : null;
    }
    function codec(node) {
        const c = node.properties["api.bluez5.codec"] ?? "";
        return ({ sbc: "SBC", sbc_xq: "SBC-XQ", aac: "AAC", ldac: "LDAC", aptx: "aptX", aptx_hd: "aptX HD", aptx_ll: "aptX LL",
                  opus_05: "Opus", lc3: "LC3", msbc: "mSBC", cvsd: "CVSD" })[c] ?? c.toUpperCase();
    }
    function profileName(key, p) {
        const d = p?.description ?? key;
        return d.replace(/^High Fidelity Playback \(A2DP Sink(, codec )?/i, "Музыка ")
                .replace(/^Headset Head Unit \(HSP\/HFP(, codec )?/i, "Звонки ")
                .replace(/\)$/, "").trim();
    }

    function stem(n) { return (n?.name ?? "").replace(/^(alsa_output|alsa_input|bluez_output|bluez_input)\./, "").replace(/\.[^.]*$/, ""); }
    readonly property var routes: Audio.sinks.map(s => ({ sink: s, source: Audio.sources.find(x => root.stem(x) === root.stem(s)) ?? null }))

    MText { x: 4; textStyle: Type.titleSmall; text: "Куда звук" }

    Flow {
        width: root.width
        spacing: 8
        Repeater {
            model: root.routes
            Rectangle {
                id: route
                required property var modelData
                readonly property bool on: Audio.sink === modelData.sink
                width: (root.width - 8) / 2
                height: 72
                radius: on ? height / 2 : Shape.largeIncreased
                color: on ? Colors.m3primary : Colors.m3surfaceContainerHighest
                Behavior on radius { SpatialAnim { speed: "fast" } }
                Behavior on color { ColorAnim {} }
                scale: rp.value
                SpringValue { id: rp; target: routeL.pressed ? 0.95 : 1; damping: 0.5; stiffness: 800; epsilon: 0.001 }
                StateLayer {
                    id: routeL
                    radius: route.radius
                    color: route.on ? Colors.m3onPrimary : Colors.m3onSurface
                    onClicked: {
                        Audio.setDefault(route.modelData.sink);
                        if (route.modelData.source) Audio.setDefault(route.modelData.source);
                    }
                }
                Row {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    width: parent.width - 36
                    MIcon { anchors.verticalCenter: parent.verticalCenter; icon: Audio.deviceIcon(route.modelData.sink); size: 24; fill: route.on ? 1 : 0; color: route.on ? Colors.m3onPrimary : Colors.m3onSurfaceVariant }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 36
                        FlowText { width: parent.width; elide: Text.ElideRight; textStyle: Type.labelLargeEmph; color: route.on ? Colors.m3onPrimary : Colors.m3onSurface; text: Audio.label(route.modelData.sink) }
                        FlowText {
                            width: parent.width; elide: Text.ElideRight; textStyle: Type.labelMedium
                            color: route.on ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            text: route.modelData.source ? "Звук и микрофон" : "Только звук"
                        }
                    }
                }
            }
        }
    }

    ListGroup {
        width: root.width
        title: "Выходы"
        Repeater {
            model: ScriptModel { values: Audio.sinks }
            SettingRow {
                id: out
                required property var modelData
                readonly property var dev: root.btDevice(modelData)
                color: Audio.sink === modelData ? Colors.m3secondaryContainer : Colors.m3surfaceContainerHigh
                icon: Audio.deviceIcon(modelData)
                title: Audio.label(modelData)
                subtitle: [root.codec(modelData), dev?.batteryAvailable ? "заряд " + Math.round(dev.battery * 100) + "%" : ""].filter(Boolean).join(" · ")
                clickable: true
                onClicked: Audio.setDefault(modelData)
                MRadio { checked: Audio.sink === out.modelData }
                below: Row {
                    width: parent.width
                    spacing: 4
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 36; iconSize: 20
                        icon: out.modelData.audio?.muted ? "volume_off" : "volume_up"
                        onClicked: out.modelData.audio.muted = !out.modelData.audio.muted
                    }
                    MSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        value: out.modelData.audio?.muted ? 0 : (out.modelData.audio?.volume ?? 0)
                        onMoved: v => { out.modelData.audio.muted = false; out.modelData.audio.volume = v; }
                    }
                }
            }
        }
    }

    Rectangle {
        width: root.width
        height: eqCol.implicitHeight + 32
        radius: Shape.extraLarge
        color: Colors.m3surfaceContainerHigh

        Column {
            id: eqCol
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 14

            Item {
                width: parent.width
                height: 40
                MIcon { id: eqIcon; anchors.verticalCenter: parent.verticalCenter; icon: "equalizer"; size: 24; color: Colors.m3onSurfaceVariant }
                Column {
                    anchors.left: eqIcon.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    MText { textStyle: Type.titleSmall; text: "Эквалайзер" }
                }
                MSwitch { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; checked: Eq.on; onToggled: c => Eq.setOn(c) }
            }

            Flow {
                width: parent.width
                spacing: 8
                opacity: Eq.on ? 1 : 0.45
                enabled: Eq.on
                Behavior on opacity { EffectAnim {} }
                Repeater {
                    model: Eq.presets
                    FilterChip {
                        required property var modelData
                        text: modelData.label
                        picked: Eq.preset === modelData.id
                        onClicked: Eq.usePreset(modelData.id)
                    }
                }
            }

            Row {
                id: bands
                width: parent.width
                height: 168
                opacity: Eq.on ? 1 : 0.45
                enabled: Eq.on
                Behavior on opacity { EffectAnim {} }
                Repeater {
                    model: Eq.bands.length
                    Item {
                        id: band
                        required property int index
                        readonly property real db: Eq.gains[index]
                        width: bands.width / Eq.bands.length
                        height: bands.height
                        readonly property real trackH: height - 44
                        SpringValue { id: kv; target: band.db; damping: 0.7; stiffness: 520; epsilon: 0.01 }
                        readonly property real ky: 18 + band.trackH / 2 - kv.value / 12 * band.trackH / 2

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 18
                            width: 6
                            height: band.trackH
                            radius: 3
                            color: Colors.m3secondaryContainer
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: Math.min(band.ky, 18 + band.trackH / 2)
                            width: 6
                            height: Math.abs(band.ky - (18 + band.trackH / 2))
                            radius: 3
                            color: Colors.m3primary
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: band.ky - height / 2
                            width: bandDrag.pressed ? 22 : 18
                            height: bandDrag.pressed ? 10 : 8
                            radius: height / 2
                            color: Colors.m3primary
                            Behavior on width { SpatialAnim { speed: "fast" } }
                        }
                        MText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 0
                            textStyle: Type.labelSmall
                            color: Colors.m3primary
                            opacity: bandDrag.pressed || Math.abs(band.db) > 0.01 ? 1 : 0
                            Behavior on opacity { EffectAnim {} }
                            text: (band.db > 0 ? "+" : "") + band.db
                        }
                        MText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            textStyle: Type.labelSmall
                            color: Colors.m3onSurfaceVariant
                            text: { const f = Eq.bands[band.index]; return f >= 1000 ? f / 1000 + "к" : String(f); }
                        }
                        MouseArea {
                            id: bandDrag
                            anchors.fill: parent
                            preventStealing: true
                            cursorShape: Qt.SizeVerCursor
                            function set(y) { Eq.setGain(band.index, (18 + band.trackH / 2 - y) / (band.trackH / 2) * 12); }
                            onPressed: m => set(m.y)
                            onPositionChanged: m => { if (pressed) set(m.y); }
                            onDoubleClicked: Eq.setGain(band.index, 0)
                        }
                    }
                }
            }
        }
    }

    function codecName(key) {
        return ({ sbc: "SBC", sbc_xq: "SBC-XQ", aac: "AAC", ldac: "LDAC", aptx: "aptX", aptx_hd: "aptX HD", aptx_ll: "aptX LL",
                  aptx_ll_duplex: "aptX LL", faststream: "FastStream", opus_05: "Opus", opus_g: "Opus", lc3: "LC3",
                  msbc: "mSBC", cvsd: "CVSD", lc3_swb: "LC3-SWB" })[key] ?? key.toUpperCase();
    }
    Repeater {
        model: root.btSinks
        Rectangle {
            id: bt
            required property var modelData
            readonly property var card: root.cardOf(modelData)
            readonly property var dev: root.btDevice(modelData)
            readonly property string active: card?.active_profile ?? ""
            readonly property bool calls: active.startsWith("headset")
            readonly property string family: calls ? "headset-head-unit" : "a2dp-sink"
            readonly property var keys: card ? Object.keys(card.profiles ?? {}).filter(k => card.profiles[k].available !== false) : []
            readonly property bool canCalls: keys.some(k => k.startsWith("headset"))
            readonly property var codecs: keys.filter(k => k === family || k.startsWith(family + "-"))
                                              .sort((x, y) => (x === family ? -1 : y === family ? 1 : 0))
            readonly property string now: root.codec(modelData)
            readonly property real charge: dev?.batteryAvailable ? dev.battery : -1

            width: root.width
            height: btCol.implicitHeight + 32
            radius: Shape.extraLarge
            color: Colors.m3surfaceContainerHigh

            Column {
                id: btCol
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 16

                Item {
                    width: parent.width
                    height: 64
                    MaterialShape {
                        id: btShape
                        width: 64
                        height: 64
                        shape: "cookie9Sided"
                        color: bt.charge >= 0 && bt.charge <= 0.15 ? Colors.m3errorContainer : Colors.m3primaryContainer
                        SpringValue { id: btTurn; target: bt.calls ? 40 : 0; damping: 0.5; stiffness: 200 }
                        rotation: btTurn.value
                        MIcon {
                            anchors.centerIn: parent
                            rotation: -btShape.rotation
                            icon: bt.calls ? "headset_mic" : "headphones"
                            size: 30
                            fill: 1
                            color: Colors.m3onPrimaryContainer
                        }
                    }
                    Column {
                        anchors.left: btShape.right
                        anchors.leftMargin: 16
                        anchors.right: btPct.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        FlowText { width: parent.width; elide: Text.ElideRight; textStyle: Type.titleMediumEmph; text: bt.dev?.name ?? Audio.label(bt.modelData) }
                        FlowText {
                            width: parent.width
                            elide: Text.ElideRight
                            textStyle: Type.labelMedium
                            color: Colors.m3onSurfaceVariant
                            text: (bt.calls ? "Звонки" : "Музыка") + (bt.now ? " · " + bt.now : "")
                        }
                    }
                    RollingText {
                        id: btPct
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: bt.charge >= 0
                        pixelSize: 34
                        weight: 650
                        color: bt.charge >= 0 && bt.charge <= 0.15 ? Colors.m3error : Colors.m3onSurface
                        text: Math.round(bt.charge * 100) + "%"
                    }
                }

                Row {
                    id: modes
                    visible: bt.canCalls
                    width: parent.width
                    height: 52
                    spacing: 3
                    Repeater {
                        model: [{ calls: false, icon: "music_note", label: "Музыка" },
                                { calls: true, icon: "call", label: "Звонки" }]
                        Rectangle {
                            id: seg
                            required property var modelData
                            required property int index
                            readonly property bool on: bt.calls === modelData.calls
                            width: (modes.width - modes.spacing) / 2
                            height: modes.height
                            SpringValue { id: segR; target: on || segL.pressed ? 1 : 0; damping: 0.55; stiffness: 600 }
                            readonly property real inner: 8 + (height / 2 - 8) * Math.max(0, Math.min(1, segR.value))
                            topLeftRadius: index === 0 ? height / 2 : inner
                            bottomLeftRadius: index === 0 ? height / 2 : inner
                            topRightRadius: index === 1 ? height / 2 : inner
                            bottomRightRadius: index === 1 ? height / 2 : inner
                            color: on ? Colors.m3primary : Colors.m3secondaryContainer
                            Behavior on color { ColorAnim {} }
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                MIcon { anchors.verticalCenter: parent.verticalCenter; icon: seg.modelData.icon; size: 20; fill: seg.on ? 1 : 0; color: seg.on ? Colors.m3onPrimary : Colors.m3onSecondaryContainer }
                                MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLargeEmph; color: seg.on ? Colors.m3onPrimary : Colors.m3onSecondaryContainer; text: seg.modelData.label }
                            }
                            StateLayer {
                                id: segL
                                topLeftRadius: seg.topLeftRadius
                                bottomLeftRadius: seg.bottomLeftRadius
                                topRightRadius: seg.topRightRadius
                                bottomRightRadius: seg.bottomRightRadius
                                color: seg.on ? Colors.m3onPrimary : Colors.m3onSecondaryContainer
                                onClicked: if (!seg.on) root.setProfile(bt.card, seg.modelData.calls ? "headset-head-unit" : "a2dp-sink")
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: bt.codecs.length > 0
                    MText { textStyle: Type.labelLargeEmph; color: Colors.m3onSurfaceVariant; text: "Кодек" }
                    Flow {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: bt.codecs
                            FilterChip {
                                required property string modelData
                                readonly property string key: modelData === bt.family ? "" : modelData.slice(bt.family.length + 1)
                                text: key ? root.codecName(key) : "Авто" + (bt.active === bt.family && bt.now ? " · " + bt.now : "")
                                picked: bt.active === modelData
                                onClicked: root.setProfile(bt.card, modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    ListGroup {
        width: root.width
        title: "Микрофоны"
        visible: Audio.sources.length > 0
        Repeater {
            model: ScriptModel { values: Audio.sources }
            SettingRow {
                id: inp
                required property var modelData
                color: Audio.source === modelData ? Colors.m3secondaryContainer : Colors.m3surfaceContainerHigh
                icon: modelData.audio?.muted ? "mic_off" : "mic"
                title: Audio.label(modelData)
                clickable: true
                onClicked: Audio.setDefault(modelData)
                MRadio { checked: Audio.source === inp.modelData }
                below: MSlider {
                    width: parent.width
                    value: inp.modelData.audio?.muted ? 0 : (inp.modelData.audio?.volume ?? 0)
                    onMoved: v => { inp.modelData.audio.muted = false; inp.modelData.audio.volume = v; }
                }
            }
        }
    }

    ListGroup {
        width: root.width
        title: "Приложения"
        visible: Audio.streams.length > 0

        Repeater {
            model: ScriptModel { values: Audio.streams }

            SettingRow {
                id: stream
                required property var modelData
                readonly property string app: modelData.properties["application.name"] ?? Audio.label(modelData)
                readonly property string sinkName: root.streamSink[String(modelData.id)] ?? (Audio.sink?.name ?? "")
                color: Colors.m3surfaceContainerHigh
                icon: modelData.audio.muted ? "volume_off" : "graphic_eq"
                title: stream.app
                subtitle: modelData.properties["media.name"] ?? ""

                IconButton {
                    icon: stream.modelData.audio.muted ? "volume_off" : "volume_up"
                    size: 36
                    iconSize: 20
                    onClicked: stream.modelData.audio.muted = !stream.modelData.audio.muted
                }

                below: Column {
                    width: parent.width
                    spacing: 8
                    MSlider {
                        width: parent.width
                        value: stream.modelData.audio.volume
                        onMoved: v => stream.modelData.audio.volume = v
                    }
                    Flow {
                        width: parent.width
                        spacing: 6
                        visible: Audio.sinks.length > 1
                        Repeater {
                            model: Audio.sinks
                            FilterChip {
                                required property var modelData
                                text: Audio.label(modelData)
                                picked: stream.sinkName === modelData.name
                                onClicked: root.moveStream(stream.modelData, modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}

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

    Repeater {
        model: root.btSinks
        Rectangle {
            id: bt
            required property var modelData
            readonly property var card: root.cardOf(modelData)
            readonly property var dev: root.btDevice(modelData)
            readonly property var profiles: card ? Object.entries(card.profiles ?? {}).filter(e => e[0] !== "off" && e[1].available !== false) : []
            width: root.width
            height: btCol.implicitHeight + 28
            radius: Shape.largeIncreased
            color: Colors.m3surfaceContainerHigh

            Column {
                id: btCol
                x: 16; y: 14
                width: parent.width - 32
                spacing: 12
                Row {
                    spacing: 12
                    MaterialShape {
                        width: 48; height: 48
                        shape: "cookie9Sided"
                        color: Colors.m3primaryContainer
                        MIcon { anchors.centerIn: parent; icon: "headphones"; size: 24; fill: 1; color: Colors.m3onPrimaryContainer }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        MText { textStyle: Type.titleSmall; text: bt.dev?.name ?? Audio.label(bt.modelData) }
                        MText { textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: "Кодек " + (root.codec(bt.modelData) || "—") }
                    }
                }
                BatteryPill {
                    visible: bt.dev?.batteryAvailable ?? false
                    size: 18
                    textSize: 16
                    level: bt.dev?.battery ?? 0
                }
                MText { visible: bt.profiles.length > 1; textStyle: Type.labelLarge; color: Colors.m3onSurfaceVariant; text: "Режим" }
                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: bt.profiles
                        FilterChip {
                            required property var modelData
                            text: root.profileName(modelData[0], modelData[1])
                            picked: bt.card?.active_profile === modelData[0]
                            onClicked: root.setProfile(bt.card, modelData[0])
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

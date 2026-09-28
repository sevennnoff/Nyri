import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.theme
import qs.services
import qs.widgets

Column {
    id: root

    signal back
    property var asking: null
    spacing: 16

    Component.onCompleted: Net.scan(true)
    Component.onDestruction: Net.scan(false)

    PageHeader {
        title: "Wi-Fi"
        hasSwitch: true
        checked: Net.enabled
        onBack: root.back()
        onToggled: c => Networking.wifiEnabled = c
    }

    property var info: ({})
    property real down: 0
    property real up: 0
    property var prev: null
    Process {
        id: netinfo
        command: [Paths.bin + "/nyri-netinfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const t = Date.now();
                    if (root.prev && d.rxBytes >= root.prev.rx) {
                        const dt = (t - root.prev.t) / 1000;
                        root.down = (d.rxBytes - root.prev.rx) / dt;
                        root.up = (d.txBytes - root.prev.tx) / dt;
                    }
                    root.prev = { t, rx: d.rxBytes, tx: d.txBytes };
                    root.info = d;
                } catch (e) {}
            }
        }
    }
    Timer { running: Net.enabled && Net.network !== null; interval: 2000; repeat: true; triggeredOnStart: true; onTriggered: netinfo.running = true }
    function rate(b) {
        const bits = b * 8;
        return bits >= 1e6 ? (bits / 1e6).toFixed(bits >= 1e8 ? 0 : 1) + " Мбит/с" : Math.round(bits / 1e3) + " Кбит/с";
    }

    Rectangle {
        visible: Net.enabled && Net.network !== null
        width: root.width
        height: netCol.implicitHeight + 32
        radius: Shape.extraLarge
        color: Colors.m3surfaceContainerHigh

        Column {
            id: netCol
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 14

            Item {
                width: parent.width
                height: 64
                Item {
                    id: sig
                    width: 64
                    height: 64
                    SpringValue { id: sigV; target: (Net.network?.signalStrength ?? 0); damping: 1; stiffness: 80 }
                    CircularProgress { anchors.fill: parent; stroke: 6; value: sigV.value; animated: false }
                    MIcon { anchors.centerIn: parent; icon: Net.icon; size: 26; fill: 1; color: Colors.m3primary }
                }
                Column {
                    anchors.left: sig.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    MText { width: parent.width; elide: Text.ElideRight; textStyle: Type.titleMediumEmph; text: Net.label }
                    MText {
                        width: parent.width
                        elide: Text.ElideRight
                        textStyle: Type.labelMedium
                        color: Colors.m3onSurfaceVariant
                        text: [Net.strength + "%" + (root.info.dbm ? " · " + root.info.dbm + " дБм" : ""), root.info.standard].filter(Boolean).join(" · ")
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [{ icon: "arrow_downward", label: "Загрузка", v: root.down }, { icon: "arrow_upward", label: "Отдача", v: root.up }]
                    Rectangle {
                        required property var modelData
                        width: (parent.width - 8) / 2
                        height: 64
                        radius: Shape.large
                        color: Colors.m3surfaceContainerHighest
                        Row {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            MaterialShape { anchors.verticalCenter: parent.verticalCenter; width: 36; height: 36; shape: "cookie9Sided"; color: Colors.m3secondaryContainer
                                MIcon { anchors.centerIn: parent; icon: modelData.icon; size: 20; fill: 1; color: Colors.m3onSecondaryContainer } }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                MText { textStyle: Type.titleSmall; font.features: { "tnum": 1 }; text: root.rate(modelData.v) }
                                MText { textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: modelData.label }
                            }
                        }
                    }
                }
            }

            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: [
                        root.info.band ? root.info.band + (root.info.channel ? ", канал " + root.info.channel : "") + (root.info.width ? ", " + root.info.width + " МГц" : "") : "",
                        root.info.tx ? "связь " + Math.round(root.info.tx) + " / " + Math.round(root.info.rx ?? 0) + " Мбит/с" : "",
                        Net.network && Net.secured(Net.network) ? "защищена" : "",
                        root.info.ip ? "IP " + root.info.ip + (root.info.prefix ? "/" + root.info.prefix : "") : "",
                        root.info.gateway ? "шлюз " + root.info.gateway : "",
                        (root.info.dns ?? []).length ? "DNS " + root.info.dns.join(", ") : "",
                        root.info.mac ? "MAC " + root.info.mac : ""
                    ].filter(Boolean)
                    Rectangle {
                        required property string modelData
                        height: 32
                        width: chipT.implicitWidth + 24
                        radius: 16
                        color: Colors.m3surfaceContainerHighest
                        MText { id: chipT; anchors.centerIn: parent; textStyle: Type.labelLarge; color: Colors.m3onSurfaceVariant; text: modelData }
                    }
                }
            }
        }
    }

    MText {
        visible: !Net.enabled
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        textStyle: Type.bodyMedium
        color: Colors.m3onSurfaceVariant
        text: "Wi-Fi выключен"
    }

    ListGroup {
        width: root.width
        visible: Net.enabled

        Repeater {
            model: ScriptModel { values: Net.networks }

            SettingRow {
                id: row
                required property var modelData
                readonly property bool busy: modelData.stateChanging
                color: modelData.connected ? Colors.m3secondaryContainer : Colors.m3surfaceContainerHigh
                icon: Net.signalIcon(modelData)
                title: Net.nameOf(modelData)
                subtitle: busy ? "Подключаюсь…"
                        : modelData.connected ? "Подключено"
                        : modelData.known ? "Сохранена"
                        : Net.secured(modelData) ? "Защищена" : "Открытая"
                clickable: true
                onClicked: {
                    if (modelData.connected) return;
                    if (modelData.known || !Net.secured(modelData)) modelData.connect();
                    else root.asking = root.asking === modelData ? null : modelData;
                }

                MIcon {
                    visible: Net.secured(row.modelData)
                    icon: "lock"
                    size: 18
                    color: Colors.m3onSurfaceVariant
                }

                IconButton {
                    visible: row.modelData.connected || row.modelData.known
                    icon: row.modelData.connected ? "link_off" : "delete"
                    size: 36
                    iconSize: 18
                    onClicked: row.modelData.connected ? row.modelData.disconnect() : row.modelData.forget()
                }

                below: Row {
                    visible: root.asking === row.modelData
                    width: parent.width
                    spacing: 8

                    SearchField {
                        id: psk
                        width: parent.width - 56
                        icon: "key"
                        placeholder: "Пароль"
                        input.echoMode: TextInput.Password
                        input.onAccepted: go.clicked()
                        Component.onCompleted: input.forceActiveFocus()
                    }

                    IconButton {
                        id: go
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "arrow_forward"
                        style: "filled"
                        size: 48
                        onClicked: {
                            row.modelData.connectWithPsk(psk.text);
                            root.asking = null;
                        }
                    }
                }
            }
        }
    }
}

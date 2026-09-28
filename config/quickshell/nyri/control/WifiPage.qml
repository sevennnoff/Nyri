import QtQuick
import Quickshell
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

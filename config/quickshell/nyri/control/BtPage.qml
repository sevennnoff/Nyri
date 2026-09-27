import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.theme
import qs.services
import qs.widgets

// Bluetooth devices. Discovery runs only while this page is open.
Column {
    id: root

    signal back
    spacing: 16

    Component.onCompleted: Bt.discover(true)
    Component.onDestruction: Bt.discover(false)

    PageHeader {
        title: "Bluetooth"
        hasSwitch: true
        checked: Bt.enabled
        onBack: root.back()
        onToggled: c => { if (Bt.adapter) { Bt.adapter.enabled = c; if (c) Qt.callLater(() => Bt.discover(true)); } }
    }

    component DeviceRow: SettingRow {
        id: row
        required property var modelData
        color: modelData.connected ? Colors.m3secondaryContainer : Colors.m3surfaceContainerHigh
        icon: Bt.deviceIcon(modelData)
        title: modelData.name
        subtitle: modelData.pairing ? "Сопряжение…"
                : modelData.state === BluetoothDeviceState.Connecting ? "Подключаюсь…"
                : modelData.connected ? ("Подключено" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : ""))
                : (modelData.paired || modelData.bonded) ? "Не подключено" : "Нажми, чтобы подключить"
        clickable: true
        onClicked: Bt.activate(modelData)

        // A freshly paired device connects right away.
        Connections {
            target: row.modelData
            function onPairedChanged() { if (row.modelData.paired) row.modelData.connect() }
        }

        IconButton {
            visible: row.modelData.paired || row.modelData.bonded
            icon: "delete"
            size: 36
            iconSize: 18
            onClicked: row.modelData.forget()
        }
    }

    ListGroup {
        width: root.width
        title: "Мои устройства"
        visible: Bt.enabled && Bt.paired.length > 0

        Repeater {
            model: ScriptModel { values: Bt.paired }
            DeviceRow {}
        }
    }

    ListGroup {
        width: root.width
        title: Bt.adapter?.discovering ? "Поиск устройств…" : "Доступные"
        visible: Bt.enabled

        Repeater {
            model: ScriptModel { values: Bt.available }
            DeviceRow {}
        }
    }

    MText {
        visible: !Bt.enabled
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        textStyle: Type.bodyMedium
        color: Colors.m3onSurfaceVariant
        text: Bt.adapter ? "Bluetooth выключен" : "Адаптер не найден"
    }
}

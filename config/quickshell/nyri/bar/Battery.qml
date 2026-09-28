import QtQuick
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.theme
import qs.widgets

Row {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real level: {
        const p = dev?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
                                  || dev?.state === UPowerDeviceState.PendingCharge
    readonly property bool low: level <= 0.15 && !charging

    visible: dev?.isLaptopBattery ?? false
    spacing: 2

    MIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.charging
        icon: "bolt"
        size: 16
        fill: 1
        color: Colors.m3primary
    }

    BatteryPill {
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        height: 20
        level: root.level
        charging: root.charging
    }
}

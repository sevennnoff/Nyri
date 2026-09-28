pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connected: (adapter?.devices.values ?? []).filter(d => d.connected)
    readonly property string label: !adapter ? "Нет адаптера"
        : !enabled ? "Выключен"
        : connected.length === 1 ? connected[0].name
        : connected.length > 1 ? connected.length + " устройства"
        : "Включён"

    readonly property var devices: (adapter?.devices.values ?? []).filter(d => d.name && d.name !== d.address)
    readonly property var paired: devices.filter(d => d.paired || d.bonded)
    readonly property var available: devices.filter(d => !d.paired && !d.bonded)

    function discover(on) {
        if (adapter && adapter.enabled) adapter.discovering = on;
    }

    function deviceIcon(dev) {
        const i = dev?.icon ?? "";
        if (i.includes("headset") || i.includes("headphone") || i.includes("audio")) return "headphones";
        if (i.includes("keyboard")) return "keyboard";
        if (i.includes("mouse")) return "mouse";
        if (i.includes("phone")) return "smartphone";
        if (i.includes("computer")) return "computer";
        if (i.includes("gaming") || i.includes("joystick")) return "sports_esports";
        return "bluetooth";
    }

    function activate(dev) {
        if (dev.paired || dev.bonded) {
            dev.connected ? dev.disconnect() : dev.connect();
        } else {
            dev.trusted = true;
            dev.pair();
        }
    }

    function toggle() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
}

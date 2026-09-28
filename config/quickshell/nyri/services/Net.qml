pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool enabled: Networking.wifiEnabled
    readonly property int strength: Math.round((network?.signalStrength ?? 0) * 100)

    readonly property string icon: wired ? "lan"
        : !enabled ? "wifi_off"
        : !network ? "wifi_find"
        : strength > 66 ? "network_wifi" : strength > 33 ? "network_wifi_2_bar" : "network_wifi_1_bar"
    readonly property string label: wired ? "Кабель" : network ? nameOf(network) : (enabled ? "Не подключено" : "Выключен")

    readonly property var aliases: {
        const out = {};
        for (const pair of (Quickshell.env("NYRI_WIFI_ALIASES") || "").split(";")) {
            const i = pair.indexOf("=");
            if (i > 0) out[pair.slice(0, i)] = pair.slice(i + 1);
        }
        return out;
    }
    function nameOf(net) { return aliases[net?.name] ?? net?.name ?? ""; }

    readonly property var networks: (wifi?.networks.values ?? []).slice().sort((a, b) =>
        (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    function secured(net) {
        return net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Unknown;
    }

    function signalIcon(net) {
        const s = net.signalStrength;
        return s > 0.75 ? "network_wifi" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    function scan(on) {
        if (wifi) wifi.scannerEnabled = on;
    }

    function toggle() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}

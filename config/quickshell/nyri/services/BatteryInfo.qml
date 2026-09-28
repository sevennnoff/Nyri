pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    property var history: []
    property int cycles: -1

    readonly property real health: device?.healthSupported ? device.healthPercentage : -1
    readonly property real rate: Math.abs(device?.changeRate ?? 0)

    function refresh() {
        if (!device) return;
        hist.command = ["gdbus", "call", "--system", "--dest", "org.freedesktop.UPower",
                        "--object-path", "/org/freedesktop/UPower/devices/battery_" + device.nativePath.split("/").pop(),
                        "--method", "org.freedesktop.UPower.Device.GetHistory", "charge", "86400", "120"];
        hist.running = true;
        cyc.reload();
    }

    Process {
        id: hist
        stdout: StdioCollector {
            onStreamFinished: {
                const pts = [];
                const re = /\((?:uint32 )?(\d+), ([\d.]+), (?:uint32 )?(\d+)\)/g;
                let m;
                while ((m = re.exec(text)) !== null)
                    pts.push({ t: parseInt(m[1]) * 1000, v: parseFloat(m[2]), charging: m[3] === "1" || m[3] === "4" });
                root.history = pts.reverse();
            }
        }
    }

    FileView {
        id: cyc
        path: root.device ? "/sys/class/power_supply/" + root.device.nativePath.split("/").pop() + "/cycle_count" : ""
        onLoaded: root.cycles = parseInt(text()) || -1
    }
}

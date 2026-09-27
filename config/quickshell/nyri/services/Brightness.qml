pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via sysfs. sysfs does not emit inotify events, so instead of
// polling this re-reads only when something changes brightness: the keys
// (through `nyri brightness ...` -> IPC) or the slider here.
Singleton {
    id: root

    property string device: ""
    property real value: 0
    property real max: 1
    readonly property bool available: device !== ""
    readonly property real level: max > 0 ? value / max : 0

    function refresh() {
        if (!available)
            return;
        current.reload();
    }

    function set(level) {
        const pct = Math.round(Math.max(0.01, Math.min(1, level)) * 100);
        root.value = pct / 100 * root.max;
        Quickshell.execDetached(["brightnessctl", "-q", "-e4", "-n2", "set", pct + "%"]);
    }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = text.trim();
                if (dev) {
                    maxFile.path = "/sys/class/backlight/" + dev + "/max_brightness";
                    current.path = "/sys/class/backlight/" + dev + "/brightness";
                    root.device = dev;
                }
            }
        }
    }

    FileView {
        id: maxFile
        onLoaded: root.max = parseInt(text()) || 1
    }

    FileView {
        id: current
        onLoaded: root.value = parseInt(text()) || 0
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int watchers: 0
    property real cpu: 0
    property real mem: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real temp: 0
    property real disk: 0
    property string diskText: ""

    property var lastCpu: null
    property string tempPath: ""

    Timer {
        running: root.watchers > 0
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root.tempPath) tempFile.reload();
        }
    }

    onWatchersChanged: if (watchers > 0) df.running = true

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total, di = idle - root.lastCpu.idle;
                root.cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
            }
            root.lastCpu = { total, idle };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kv = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m) kv[m[1]] = parseInt(m[2]);
            }
            root.memTotalGb = kv.MemTotal / 1048576;
            root.memUsedGb = (kv.MemTotal - kv.MemAvailable) / 1048576;
            root.mem = root.memUsedGb / root.memTotalGb;
        }
    }

    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.temp = parseInt(text()) / 1000
    }

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do n=$(cat $d/name); case $n in k10temp|coretemp|zenpower) echo $d/temp1_input; exit;; esac; done"]
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [used, size] = text.trim().split("\n")[1].trim().split(/\s+/).map(Number);
                root.disk = used / size;
                root.diskText = Math.round(used / 1e9) + " / " + Math.round(size / 1e9) + " ГБ";
            }
        }
    }
}

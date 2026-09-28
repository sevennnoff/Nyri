import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

Scope {
    id: root

    readonly property bool battery: UPower.onBattery

    readonly property var cfg: Config.o.idle
    readonly property int lockMinutes: battery ? cfg.lockBattery : cfg.lockAc

    IdleMonitor {
        enabled: root.cfg.screenOff > 0
        timeout: root.cfg.screenOff * 60
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"])
    }

    IdleMonitor {
        enabled: root.lockMinutes > 0 && !Panels.nested
        timeout: root.lockMinutes * 60
        onIsIdleChanged: if (isIdle) Lock.lock()
    }

    IdleMonitor {
        enabled: root.battery && !Panels.nested && root.cfg.suspendBattery > 0
        timeout: root.cfg.suspendBattery * 60
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }

    Process {
        running: !Panels.nested
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1",
                  "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => { if (line.includes("PrepareForSleep (true")) Lock.lock() }
        }
    }

    Process {
        running: !Panels.nested && root.cfg.lockOnLogin
        command: ["sh", "-c", "m=\"$XDG_RUNTIME_DIR/nyri-locked-once\"; [ -e \"$m\" ] && exit 1; touch \"$m\""]
        onExited: code => { if (code === 0) Lock.lock() }
    }
}

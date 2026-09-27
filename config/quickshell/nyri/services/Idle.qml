import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

// Idle policy (Settings → Питание и сон; defaults carried over from iNiR):
//   screen off  5 min
//   lock       10 min on AC, 15 on battery
//   suspend    20 min, battery only
// Also locks when the system is about to sleep (lid, menu, anything), and
// once at login. Keep-awake (Toggles.caffeine) is an IdleInhibitor on the bar,
// and these monitors respect inhibitors.
//
// Nested (NYRI_NESTED=1): nothing here touches the real machine.
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
        enabled: root.lockMinutes > 0
        timeout: root.lockMinutes * 60
        onIsIdleChanged: if (isIdle) Lock.lock()
    }

    IdleMonitor {
        enabled: root.battery && !Panels.nested && root.cfg.suspendBattery > 0
        timeout: root.cfg.suspendBattery * 60
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }

    // logind announces sleep with PrepareForSleep(true). Event-driven: the
    // monitor just blocks on the system bus.
    Process {
        running: !Panels.nested
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1",
                  "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => { if (line.includes("PrepareForSleep (true")) Lock.lock() }
        }
    }

    // Lock once per login (the old shell did too). The marker lives in the
    // runtime dir, which logout clears, so shell reloads do not re-lock.
    Process {
        running: !Panels.nested && root.cfg.lockOnLogin
        command: ["sh", "-c", "m=\"$XDG_RUNTIME_DIR/nyri-locked-once\"; [ -e \"$m\" ] && exit 1; touch \"$m\""]
        onExited: code => { if (code === 0) Lock.lock() }
    }
}

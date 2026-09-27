pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Small switches that are processes or state rather than services.
Singleton {
    id: root

    // Gaming crosshair in the middle of the screen (Super+G).
    property bool crosshair: false

    // Screen recording, reported by bin/nyri when wf-recorder starts/stops.
    property bool recording: false
    property real recordingSince: 0

    // Caps Lock, from bin/nyri-capswatch (evdev + the Caps LED; no polling).
    property bool capsLock: false
    property bool capsReady: false
    Process {
        running: true
        command: [Quickshell.env("HOME") + "/nyri/bin/nyri-capswatch"]
        stdout: SplitParser {
            onRead: line => {
                root.capsLock = line.trim() === "1";
                if (root.capsReady) Osd.show("caps");
                root.capsReady = true;
            }
        }
    }

    // Keep-awake. The IdleInhibitor itself lives on the bar window (it needs
    // a surface); this is just the switch.
    property bool caffeine: false

    // Night light (Settings → Оформление): wlsunset, running only while on.
    // "on" holds the warm temperature all day; "auto" follows sunset and
    // sunrise at the weather location.
    readonly property bool nightLight: Config.o.night.mode !== "off"
    function setNightLight(on) { Config.o.night.mode = on ? "on" : "off"; }
    Process {
        running: root.nightLight
        command: Config.o.night.mode === "auto"
            ? ["wlsunset", "-t", String(Config.o.night.temp), "-T", "6500",
               "-l", String(Config.o.weather.lat), "-L", String(Config.o.weather.lon)]
            : ["wlsunset", "-t", String(Config.o.night.temp), "-T", String(Config.o.night.temp + 1),
               "-s", "00:00", "-S", "23:59", "-d", "1"]
    }

    readonly property bool dark: Colors.mode !== "light"
    function toggleDark() {
        Quickshell.execDetached(["env", "NYRI_MODE=" + (dark ? "light" : "dark"),
                                 Quickshell.env("HOME") + "/nyri/bin/nyri-theme"]);
    }
}

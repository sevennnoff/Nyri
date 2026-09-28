pragma Singleton
import QtQuick
import Quickshell
import qs.theme

Singleton {
    id: root

    readonly property var cfg: Config.o.theme
    readonly property bool on: cfg.schedule !== "off"

    function sun(date) {
        const lat = Config.o.weather.lat, lon = Config.o.weather.lon;
        const rad = Math.PI / 180;
        const start = new Date(date.getFullYear(), 0, 0);
        const day = Math.floor((date - start) / 86400000);
        const g = 2 * Math.PI / 365 * (day - 1);
        const eq = 229.18 * (0.000075 + 0.001868 * Math.cos(g) - 0.032077 * Math.sin(g) - 0.014615 * Math.cos(2 * g) - 0.040849 * Math.sin(2 * g));
        const decl = 0.006918 - 0.399912 * Math.cos(g) + 0.070257 * Math.sin(g) - 0.006758 * Math.cos(2 * g) + 0.000907 * Math.sin(2 * g) - 0.002697 * Math.cos(3 * g) + 0.00148 * Math.sin(3 * g);
        const cosH = (Math.cos(90.833 * rad) - Math.sin(lat * rad) * Math.sin(decl)) / (Math.cos(lat * rad) * Math.cos(decl));
        const tz = -date.getTimezoneOffset();
        if (cosH > 1) return { rise: 24 * 60, set: 0 };
        if (cosH < -1) return { rise: 0, set: 24 * 60 };
        const ha = Math.acos(cosH) / rad;
        return { rise: 720 - 4 * (lon + ha) - eq + tz, set: 720 - 4 * (lon - ha) - eq + tz };
    }
    function minutes(hhmm) {
        const m = String(hhmm).match(/^(\d{1,2}):(\d{2})$/);
        return m ? +m[1] * 60 + +m[2] : 0;
    }
    function window(date) {
        if (cfg.schedule === "sun") { const s = sun(date); return { light: s.rise, dark: s.set }; }
        return { light: minutes(cfg.lightAt), dark: minutes(cfg.darkAt) };
    }
    function wanted(date) {
        const w = window(date), m = date.getHours() * 60 + date.getMinutes() + date.getSeconds() / 60;
        const day = w.light <= w.dark ? m >= w.light && m < w.dark : m >= w.light || m < w.dark;
        return day ? "light" : "dark";
    }
    function untilNext(date) {
        const w = window(date), m = date.getHours() * 60 + date.getMinutes() + date.getSeconds() / 60;
        let best = Infinity;
        for (const b of [w.light, w.dark, w.light + 1440, w.dark + 1440])
            if (b > m + 0.01) best = Math.min(best, b - m);
        return Math.max(1000, Math.round(best * 60000));
    }
    readonly property string nextText: {
        if (!on) return "";
        const d = new Date(Date.now() + untilNext(new Date()));
        return (wanted(new Date()) === "dark" ? "Светлая в " : "Тёмная в ") + Qt.formatTime(d, "HH:mm");
    }

    property string applying: ""
    function check() {
        if (!on) { tick.stop(); return; }
        const now = new Date();
        const want = wanted(now);
        if (want !== Colors.mode && applying !== want) {
            applying = want;
            if (cfg.walls) Quickshell.execDetached([Paths.bin + "/nyri-wall", "variant", want]);
            else Quickshell.execDetached(["env", "NYRI_MODE=" + want, Paths.bin + "/nyri-theme"]);
            done.restart();
        }
        tick.interval = Math.min(untilNext(now) + 1500, 3600000);
        tick.restart();
    }
    Timer { id: done; interval: 20000; onTriggered: root.applying = "" }
    Timer { id: tick; onTriggered: root.check() }

    Connections {
        target: Lock
        function onUnlocked() { root.check(); }
    }
    Connections {
        target: root.cfg
        function onScheduleChanged() { root.check(); }
        function onDarkAtChanged() { root.check(); }
        function onLightAtChanged() { root.check(); }
    }
    Connections {
        target: Colors
        function onModeChanged() { if (Colors.mode === root.applying) root.applying = ""; }
    }
    Component.onCompleted: Qt.callLater(check)
}

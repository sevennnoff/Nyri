pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Screen time per app, from niri focus events — nothing is polled. Time counts
// for the focused app only while you are actually there: not idle for 2 min,
// not locked. Stored per day, 60 days kept, in Paths.state.
// The nested test session reads the data but never adds to it.
Singleton {
    id: root

    property var days: ({})             // "yyyy-MM-dd" -> { app_id: seconds }
    property string current: ""
    property real since: 0

    readonly property bool away: idle.isIdle || Lock.locked
    readonly property string activeApp: Panels.nested || away || !Config.o.screenTime.enabled ? "" : (Niri.focusedWindow?.app_id ?? "")

    function key(d) {
        return Qt.formatDate(d, "yyyy-MM-dd");
    }

    // Credit [from, to) to `app`, split at midnight.
    function credit(app, from, to) {
        const next = Object.assign({}, days);
        while (from < to) {
            const d = new Date(from);
            const midnight = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime();
            const end = Math.min(to, midnight);
            const k = key(d);
            const day = Object.assign({}, next[k] ?? {});
            day[app] = (day[app] ?? 0) + (end - from) / 1000;
            next[k] = day;
            from = end;
        }
        days = next;
    }

    function flush() {
        const now = Date.now();
        if (current && since > 0 && now > since)
            credit(current, since, now);
        since = now;
    }

    // The nested session must not write: it would clobber the real session's
    // file with its own stale copy.
    function save() {
        if (Panels.nested)
            return;
        const cutoff = key(new Date(Date.now() - 60 * 86400000));
        const kept = {};
        for (const k in days)
            if (k >= cutoff) kept[k] = days[k];
        store.setText(JSON.stringify(kept));
    }

    function clear() {
        current = "";
        days = {};
        save();
        current = activeApp;
        since = Date.now();
    }

    // Seconds per app for a day, including the segment still running today.
    function dayTotals(date) {
        const k = key(date);
        const out = Object.assign({}, days[k] ?? {});
        if (current && k === key(new Date()))
            out[current] = (out[current] ?? 0) + (Date.now() - since) / 1000;
        return out;
    }

    function total(totals) {
        return Object.values(totals).reduce((a, b) => a + b, 0);
    }

    function fmt(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60);
        return h > 0 ? h + " ч " + m + " мин" : m > 0 ? m + " мин" : sec >= 1 ? "< 1 мин" : "0 мин";
    }

    onActiveAppChanged: {
        flush();
        current = activeApp;
        save();
    }

    IdleMonitor {
        id: idle
        timeout: 120
    }

    // Checkpoint long sessions so a crash loses at most five minutes.
    Timer {
        running: root.current !== ""
        interval: 300000
        repeat: true
        onTriggered: { root.flush(); root.save(); }
    }

    Component.onCompleted: {
        since = Date.now();
        current = activeApp;
    }
    Component.onDestruction: { flush(); save(); }

    FileView {
        id: store
        path: Paths.state + "/screentime.json"
        atomicWrites: true
        onLoaded: {
            try { root.days = JSON.parse(text()); } catch (e) {}
        }
    }
}

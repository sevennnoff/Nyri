pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
    property var counts: ({})

    function iconFor(appId) {
        if (appId === "org.quickshell")
            return "preferences-system";
        return DesktopEntries.heuristicLookup(appId)?.icon ?? appId ?? "";
    }

    function nameFor(appId) {
        if (appId === "org.quickshell")
            return "Настройки Nyri";
        return DesktopEntries.heuristicLookup(appId)?.name ?? appId ?? "";
    }

    function frecency(entry) {
        return Math.log((counts[entry.id] ?? 0) + 1);
    }

    function score(entry, q) {
        const name = entry.name.toLowerCase();
        if (name.startsWith(q)) return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 80;
        if (name.includes(q)) return 60;
        const extra = [entry.genericName, entry.comment, entry.id, ...(entry.keywords ?? [])]
            .join(" ").toLowerCase();
        if (extra.includes(q)) return 40;
        let i = 0, gaps = 0, last = -1;
        for (const ch of q) {
            const at = name.indexOf(ch, i);
            if (at < 0) return 0;
            if (last >= 0) gaps += at - last - 1;
            last = at;
            i = at + 1;
        }
        return Math.max(1, 30 - gaps);
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (q === "")
            return all.slice().sort((a, b) => frecency(b) - frecency(a) || a.name.localeCompare(b.name));
        return all
            .map(e => ({ e, s: score(e, q) }))
            .filter(x => x.s > 0)
            .sort((a, b) => (b.s + frecency(b.e) * 6) - (a.s + frecency(a.e) * 6) || a.e.name.localeCompare(b.e.name))
            .map(x => x.e);
    }

    function launch(entry) {
        const next = Object.assign({}, counts);
        next[entry.id] = (next[entry.id] ?? 0) + 1;
        counts = next;
        store.setText(JSON.stringify(next));

        const cmd = entry.runInTerminal ? ["kitty", "-e", ...entry.command] : entry.command;
        Quickshell.execDetached({ command: cmd, workingDirectory: entry.workingDirectory || Quickshell.env("HOME") });
    }

    FileView {
        id: store
        path: Paths.state + "/launches.json"
        onLoaded: {
            try { root.counts = JSON.parse(text()); } catch (e) {}
        }
    }
}

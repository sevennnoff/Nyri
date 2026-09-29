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

    readonly property var index: all.map(e => {
        const name = e.name.toLowerCase();
        const id = (e.id ?? "").toLowerCase().replace(/\.desktop$/, "");
        return { e, key: e.id, name, id, words: name.split(/[\s\-_.]+/),
                 extra: [e.genericName, e.comment, e.id, ...(e.keywords ?? [])].join(" ").toLowerCase(),
                 terms: [...new Set([name, ...name.split(/[\s\-_.]+/), id, ...id.split(/[\s\-_.]+/)])].filter(t => t) };
    })

    function rank(x) {
        return Math.log((counts[x.key] ?? 0) + 1);
    }

    function score(x, q) {
        const name = x.name;
        if (name.startsWith(q)) return 100;
        if (x.words.some(w => w.startsWith(q))) return 80;
        if (name.includes(q)) return 60;
        if (x.extra.includes(q)) return 40;
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
            return index.slice().sort((a, b) => rank(b) - rank(a) || a.name.localeCompare(b.name)).map(x => x.e);
        return index
            .map(x => ({ x, s: score(x, q) + rank(x) * 6 }))
            .filter(r => r.s > rank(r.x) * 6)
            .sort((a, b) => b.s - a.s || a.x.name.localeCompare(b.x.name))
            .map(r => r.x.e);
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

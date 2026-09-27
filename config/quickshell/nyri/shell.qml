//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.bar
import qs.osd
import qs.launcher
import qs.notifications
import qs.control
import qs.session
import qs.clipboard
import qs.wallpaper
import qs.lock
import qs.switcher
import qs.popouts
import qs.settings
import qs.overlays
import qs.snip
import qs.polkit

ShellRoot {
    Wallpaper {}
    Bar {}
    Osd {}
    Popups {}
    Launcher {}
    ControlCenter {}
    Session {}
    Clipboard {}
    Picker {}
    LockScreen {}
    Idle {}
    Switcher { id: altTab }
    Dashboard {}
    PowerPopout {}
    WindowMenu {}
    TrayPopout {}
    Settings { id: settingsApp }
    Crosshair {}
    SnipMenu {}
    PolkitDialog { id: polkit }
    ScreenCorners {}
    DemoPointer {}

    // A QML mistake on save: the old shell keeps running; say so.
    // Singletons are created on first use. Screen time has to count from
    // login, not from the first time someone opens the dashboard.
    Component.onCompleted: ScreenTime.since

    Connections {
        target: Quickshell
        function onReloadFailed(error) {
            Quickshell.execDetached(["notify-send", "-a", "nyri", "-u", "critical", "-i", "dialog-error",
                "Ошибка в шелле", error.split("\n")[0]]);
        }
    }

    // `qs -c nyri ipc call nyri <fn> [arg]` — what bin/nyri calls.
    IpcHandler {
        target: "nyri"

        function toggle(panel: string): void { Panels.anchorW = 0; Panels.toggle(panel); }
        function close(): void { Panels.close(); }
        function open(panel: string, page: string): void { Panels.anchorW = 0; Panels.open(panel, page); }
        function osd(kind: string): void { Osd.show(kind); }
        function state(): string { return JSON.stringify({ panel: Panels.current, tab: Panels.tab, screen: Panels.screen?.name ?? null, output: Niri.focusedOutput, locked: Lock.locked, windows: Object.keys(Niri.windows).length, workspaces: Niri.workspaces.length, screenTime: { app: ScreenTime.current, away: ScreenTime.away, focused: Niri.focusedWindow?.app_id ?? null } }); }
        function lock(): void { Lock.lock(); }
        // Test windows only (bin/nyri-nested): the real session never has NYRI_NESTED.
        function unlockNested(): void { if (Panels.nested) Lock.unlockRequested(); }
        function polkitDemo(): void { if (Panels.nested) polkit.showDemo(); }
        // Scripted demos (tools/demo.sh), test window only.
        function demoPointer(x: real, y: real): void { if (!Demo.allowed) return; Demo.pointer = true; Demo.x = x; Demo.y = y; }
        function demoHidePointer(): void { Demo.pointer = false; }
        function demoClick(): void { if (Demo.allowed) Demo.clicks++; }
        function demoMenu(key: string): void { if (Demo.allowed) Demo.menuRequested(key); }
        function demoMenuClose(): void { if (Demo.allowed) Demo.menuClose(); }
        function demoLook(key: string, index: int): void { if (Demo.allowed) Demo.lookRequested(key, index); }
        function demoDrag(key: string, x: real, y: real): void { if (Demo.allowed) Demo.dragRequested(key, x, y); }
        function dnd(): void { Notifs.dnd = !Notifs.dnd; }
        function dark(): void { Toggles.toggleDark(); }
        function settings(): void { settingsApp.toggle(); }
        function crosshair(): void { Toggles.crosshair = !Toggles.crosshair; }
        function autohide(): void { Config.o.bar.autohide = !Config.o.bar.autohide; }
        function recording(on: bool): void { Toggles.recording = on; if (on) Toggles.recordingSince = Date.now(); }
        function switcher(dir: string): void { altTab.step(dir === "prev" ? -1 : 1); }
    }
}

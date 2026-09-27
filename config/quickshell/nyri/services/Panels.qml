pragma Singleton
import QtQuick
import Quickshell

// Which modal surface is open. One at a time, like M3 sheets and dialogs.
Singleton {
    id: root

    property string current: ""
    property string tab: ""             // which page a multi-page popout opens on
    // The bar item a popout grows out of (screen coords). Width 0 = opened
    // from the keyboard; the popout then picks its own origin.
    property real anchorX: 0
    property real anchorW: 0

    // Set by bin/nyri-nested. Anything that would touch the real machine
    // (suspend, screen power) is skipped while testing in a window.
    readonly property bool nested: Quickshell.env("NYRI_NESTED") === "1"

    // The screen popups appear on: the one niri has focused.
    readonly property var screen: {
        const name = Niri.focusedOutput;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
    }

    // Open from a bar item: the popout grows out of it.
    function toggleFrom(name, item, page) {
        const p = item.mapToItem(null, 0, 0);
        anchorX = p.x;
        anchorW = item.width;
        toggle(name, page);
    }

    // The settings app is a window, not a popout; any menu can ask for it.
    // Kept across shell reloads, so saving a QML file does not close it.
    PersistentProperties {
        id: kept
        reloadableId: "nyri-settings"
        property bool open: false
        property string page: "look"
    }
    property alias settingsOpen: kept.open
    function openSettings(page) {
        current = "";
        if (page) settingsPage = page;
        settingsOpen = true;
    }
    property alias settingsPage: kept.page

    // The wallpaper studio is a window too. Anything that asks for the
    // "wallpaper" panel gets the window instead.
    PersistentProperties {
        id: keptStudio
        reloadableId: "nyri-studio"
        property bool open: false
    }
    property alias studioOpen: keptStudio.open

    function toggle(name, page) {
        if (name === "wallpaper") { current = ""; studioOpen = !studioOpen; return; }
        if (current === name && (page === undefined || tab === page)) {
            current = "";
        } else {
            tab = page ?? "";
            current = name;
        }
    }

    function open(name, page) {
        if (name === "wallpaper") { current = ""; studioOpen = true; return; }
        tab = page ?? "";
        current = name;
    }

    function close() {
        current = "";
    }
}

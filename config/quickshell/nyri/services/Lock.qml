pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Survives config reloads. Without this, saving any QML file while locked
    // recreated the singleton with locked=false and unlocked the session.
    PersistentProperties {
        id: state
        reloadableId: "nyri-lock"
        property bool locked: false
    }

    property alias locked: state.locked

    // The desk plays its arrival when the lock lifts: the wallpaper eases
    // in, the bar drops down, widgets land one after another.
    signal unlocked
    onLockedChanged: if (!locked) unlocked()

    // Plays the unlock animation without PAM; only honoured in nested tests.
    signal unlockRequested

    function lock() {
        Panels.close();
        state.locked = true;
    }
}

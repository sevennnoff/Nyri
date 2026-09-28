pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    PersistentProperties {
        id: state
        reloadableId: "nyri-lock"
        property bool locked: false
    }

    property alias locked: state.locked

    signal unlocked
    onLockedChanged: if (!locked) unlocked()

    signal unlockRequested

    function lock() {
        Panels.close();
        state.locked = true;
    }
}

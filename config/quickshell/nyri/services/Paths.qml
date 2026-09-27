pragma Singleton
import QtQuick
import Quickshell

// Where the shell keeps its state and data. NYRI_STATE / NYRI_DATA move them
// — bin/nyri-nested points them at a scratch copy, so the test window never
// writes into the real session's files.
Singleton {
    readonly property string state: Quickshell.env("NYRI_STATE") || Quickshell.env("HOME") + "/.local/state/nyri"
    readonly property string data: Quickshell.env("NYRI_DATA") || Quickshell.env("HOME") + "/.local/share/nyri"
}

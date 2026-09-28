pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string root: Quickshell.env("NYRI_ROOT") || Quickshell.env("HOME") + "/nyri"
    readonly property string bin: root + "/bin"
    readonly property string state: Quickshell.env("NYRI_STATE") || Quickshell.env("HOME") + "/.local/state/nyri"
    readonly property string data: Quickshell.env("NYRI_DATA") || Quickshell.env("HOME") + "/.local/share/nyri"
}

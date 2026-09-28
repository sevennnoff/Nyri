pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string state: Quickshell.env("NYRI_STATE") || Quickshell.env("HOME") + "/.local/state/nyri"
    readonly property string data: Quickshell.env("NYRI_DATA") || Quickshell.env("HOME") + "/.local/share/nyri"
}

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool allowed: Quickshell.env("NYRI_NESTED") === "1"

    property bool pointer: false
    property real x: 0
    property real y: 0
    property int clicks: 0
    property bool holding: false

    signal menuRequested(string key)
    signal lookRequested(string key, int index)
    signal dragRequested(string key, real x, real y)
    signal menuClose()
}

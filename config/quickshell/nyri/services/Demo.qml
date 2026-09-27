pragma Singleton
import QtQuick
import Quickshell

// Scripted demos (tools/demo.sh records one): a drawn pointer that glides
// between spots, and requests the widgets act on as if you had right-clicked
// or dragged them. Everything here is ignored outside the nested test window.
Singleton {
    id: root

    readonly property bool allowed: Quickshell.env("NYRI_NESTED") === "1"

    property bool pointer: false
    property real x: 0
    property real y: 0
    property int clicks: 0
    property bool holding: false          // dragging a widget: the pointer sticks to it

    signal menuRequested(string key)
    signal lookRequested(string key, int index)
    signal dragRequested(string key, real x, real y)
    signal menuClose()
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

// A small M3-styled crosshair over everything, click-through (Super+G).
// Mapped only while on.
PanelWindow {
    screen: Panels.screen
    visible: Toggles.crosshair
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "nyri-crosshair"
    WlrLayershell.layer: WlrLayer.Overlay

    Item {
        anchors.centerIn: parent
        width: 40
        height: 40

        // Four arms with a gap, outlined so they read on any background.
        Repeater {
            model: [[0, -1], [0, 1], [-1, 0], [1, 0]]

            Rectangle {
                required property var modelData
                readonly property bool vertical: modelData[0] === 0
                width: vertical ? 4 : 12
                height: vertical ? 12 : 4
                radius: 2
                x: 20 - width / 2 + modelData[0] * 12
                y: 20 - height / 2 + modelData[1] * 12
                color: Colors.m3primary
                border.width: 1
                border.color: Colors.m3shadow
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 5
            height: 5
            radius: 2.5
            color: Colors.m3primary
            border.width: 1
            border.color: Colors.m3shadow
        }
    }
}

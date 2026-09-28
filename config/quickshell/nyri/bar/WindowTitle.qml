import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Island {
    id: root

    property real maxTextWidth: 360
    readonly property var win: Niri.focusedWindow
    readonly property var entry: win ? DesktopEntries.heuristicLookup(win.app_id) : null

    widthSpeed: "fast"
    padding: 6
    spacing: 8
    opacity: win ? 1 : 0

    Behavior on opacity { EffectAnim {} }

    StateLayer {
        parent: root
        onClicked: Panels.toggleFrom("window", root)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        radius: 14
        color: Colors.m3surfaceContainerHighest

        IconImage {
            anchors.centerIn: parent
            implicitSize: 20
            source: Quickshell.iconPath(Apps.iconFor(root.win?.app_id), "application-x-executable")
        }
    }

    FlowText {
        anchors.verticalCenter: parent.verticalCenter
        rightPadding: 8
        maxWidth: root.maxTextWidth
        width: implicitWidth
        elide: Text.ElideRight
        textStyle: Type.labelLarge
        color: Colors.m3onSurface
        text: root.win?.title || root.entry?.name || root.win?.app_id || ""
    }
}

import QtQuick
import qs.theme

// M3 state layer: an overlay of the content color at 8% on hover, 10% on press.
// Corners follow the container — set `radius`, or the four corner radii for
// containers whose corners differ (grouped list rows, connected buttons).
MouseArea {
    id: root

    property color color: Colors.m3onSurface
    property real radius: height / 2
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: root.color
        opacity: root.pressed ? 0.10 : root.containsMouse ? 0.08 : 0

        Behavior on opacity { EffectAnim {} }
    }
}

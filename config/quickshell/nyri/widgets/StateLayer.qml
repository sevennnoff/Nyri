import QtQuick
import qs.theme

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

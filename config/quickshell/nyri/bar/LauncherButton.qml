import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.widgets

Item {
    id: root

    implicitWidth: 40
    implicitHeight: 40

    property real intro: 0
    scale: intro
    SpatialAnim on intro { from: 0; to: 1; speed: "slow" }

    MaterialShape {
        id: shape
        anchors.fill: parent
        shape: mouse.pressed ? "softBurst" : mouse.containsMouse ? "sunny" : "cookie9Sided"
        color: mouse.containsMouse ? Colors.m3primary : Colors.m3primaryContainer
        rotation: mouse.containsMouse ? 60 : 0

        Behavior on rotation { SpatialAnim { speed: "slow" } }
    }

    MIcon {
        anchors.centerIn: parent
        icon: "apps"
        size: 20
        fill: 1
        color: mouse.containsMouse ? Colors.m3onPrimary : Colors.m3onPrimaryContainer
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggleFrom("launcher", root)
    }
}

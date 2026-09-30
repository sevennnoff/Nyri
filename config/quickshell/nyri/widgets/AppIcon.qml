import QtQuick
import Quickshell.Widgets
import qs.theme

Item {
    id: root
    property url source
    property real implicitSize: 24
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) * 0.26
        color: Colors.m3secondaryContainer
        visible: appImage.status !== Image.Ready
        MIcon {
            anchors.centerIn: parent
            icon: "apps"
            size: Math.min(parent.width, parent.height) * 0.64
            color: Colors.m3onSecondaryContainer
        }
    }
    IconImage {
        id: appImage
        anchors.fill: parent
        source: root.source
        visible: status === Image.Ready
    }
}

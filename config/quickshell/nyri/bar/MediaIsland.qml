import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Island {
    id: root

    readonly property var player: Media.player
    visible: player !== null
    padding: 6
    spacing: 8

    StateLayer {
        parent: root
        radius: root.height / 2
        onClicked: Panels.toggleFrom("player", root)
    }

    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        radius: 14
        color: Colors.m3primaryContainer
        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(56, 56)
        }
    }
    FlowText {
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.o.bar.mediaTitle
        maxWidth: 200
        width: implicitWidth
        elide: Text.ElideRight
        textStyle: Type.labelLarge
        text: root.player?.trackTitle || root.player?.identity || ""
    }
    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        size: 28
        iconSize: 18
        icon: root.player?.isPlaying ? "pause" : "play_arrow"
        onClicked: root.player?.togglePlaying()
    }
}

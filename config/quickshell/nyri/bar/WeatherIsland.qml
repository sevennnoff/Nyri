import QtQuick
import qs.theme
import qs.services
import qs.widgets

Island {
    id: root

    readonly property var now: Weather.ready ? Weather.describe(Weather.current.code, Weather.current.day) : null
    visible: Weather.ready
    padding: 12
    spacing: 6

    StateLayer {
        parent: root
        radius: root.height / 2
        onClicked: Panels.toggleFrom("dashboard", root)
    }

    MIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: root.now?.icon ?? "cloud"
        size: 20
        fill: 1
        color: Colors.m3primary
    }
    RollingText {
        anchors.verticalCenter: parent.verticalCenter
        textStyle: Type.labelLargeEmph
        text: Weather.ready ? Weather.current.temp + "°" : ""
    }
}

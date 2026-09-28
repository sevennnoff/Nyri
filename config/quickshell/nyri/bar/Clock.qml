import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.widgets

Island {
    id: root

    color: Colors.m3primaryContainer
    padding: 18
    spacing: 10

    StateLayer {
        parent: root
        color: Colors.m3onPrimaryContainer
        onClicked: Panels.toggleFrom("dashboard", root)
    }

    SystemClock {
        id: clock
        precision: Config.o.bar.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    RollingText {
        anchors.verticalCenter: parent.verticalCenter
        textStyle: Type.titleMediumEmph
        color: Colors.m3onPrimaryContainer
        text: Qt.formatTime(clock.date, Config.o.bar.seconds ? "HH:mm:ss" : "HH:mm")
    }

    Rectangle {
        visible: Config.o.bar.date
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: 4
        radius: 2
        color: Colors.m3onPrimaryContainer
        opacity: 0.5
    }

    MText {
        visible: Config.o.bar.date
        anchors.verticalCenter: parent.verticalCenter
        textStyle: Type.labelLarge
        color: Colors.m3onPrimaryContainer
        text: Qt.locale().toString(clock.date, "ddd, d MMM")
    }
}

import QtQuick
import QtQuick.Effects
import qs.theme
import qs.services

// A floating pill on the bar. Width follows the content on a spatial spring,
// so islands stretch and settle instead of snapping when their content changes.
Item {
    id: root

    default property alias content: row.data
    property color color: Colors.m3surfaceContainer
    property int padding: 4
    property alias spacing: row.spacing
    property string widthSpeed: "default"
    // Startup: islands fall into place one by one (set per island in Bar).
    property int introIndex: 0
    property real intro: 0

    implicitHeight: 40
    implicitWidth: row.implicitWidth + padding * 2
    width: grow.value
    height: implicitHeight

    SpringValue {
        id: grow
        target: root.implicitWidth
        damping: root.widthSpeed === "fast" ? 0.9 : 0.62
        stiffness: root.widthSpeed === "fast" ? 600 : 420
        epsilon: 0.2
    }

    transform: Translate { y: (1 - root.intro) * -64 }
    opacity: Math.min(1, root.intro * 2)

    SequentialAnimation {
        id: introAnim
        running: true
        PauseAnimation { duration: 120 + root.introIndex * 70 }
        SpatialAnim { target: root; property: "intro"; from: 0; to: 1; speed: "slow" }
    }
    Connections {
        target: Lock
        function onUnlocked() { root.intro = 0; introAnim.restart(); }
    }

    RectangularShadow {
        anchors.fill: bg
        radius: bg.radius
        offset.y: 2
        blur: 8
        color: Qt.alpha(Colors.m3shadow, 0.35)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        color: root.color

        Behavior on color { ColorAnim {} }
    }

    Item {
        anchors.fill: parent
        clip: true

        Row {
            id: row
            x: root.padding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
        }
    }
}

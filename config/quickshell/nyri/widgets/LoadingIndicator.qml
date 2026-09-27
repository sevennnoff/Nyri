import QtQuick
import qs.theme

// M3 Expressive loading indicator: one shape that keeps morphing into the
// next — burst, cookie, pentagon, pill, sun, clover, oval — and turns a
// little further with every morph, on a spring. `contained` puts it in a
// rounded square, like Android's contained variant.
//
// Only ticks while `running`; a stopped indicator costs nothing.
Item {
    id: root

    property bool running: true
    property bool contained: true
    property color color: contained ? Colors.m3onPrimaryContainer : Colors.m3primary
    property color containerColor: Colors.m3primaryContainer

    readonly property var sequence: ["softBurst", "cookie9Sided", "pentagon", "pill", "sunny", "cookie4Sided", "oval"]
    property int step: 0

    implicitWidth: 96
    implicitHeight: 96

    SpringValue { id: turn; damping: 0.62; stiffness: 160; epsilon: 0.05 }

    Timer {
        running: root.running && root.visible
        interval: 650
        repeat: true
        triggeredOnStart: true
        onTriggered: { root.step = (root.step + 1) % root.sequence.length; turn.target += 90 + 45 * (root.step % 2); }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.contained
        radius: width * 0.32
        color: root.containerColor
    }

    MaterialShape {
        anchors.centerIn: parent
        width: parent.width * (root.contained ? 0.62 : 1)
        height: width
        rotation: turn.value
        shape: root.sequence[root.step]
        color: root.color
    }
}

import QtQuick
import qs.theme

// M3 Expressive slider: split track with a gap around a thin handle, rounded
// outer ends and near-square inner ends, a stop dot, and (for tall tracks) an
// icon inset at the start of the active track. The handle narrows while held.
Item {
    id: root

    property real value: 0                 // 0..1
    property int trackHeight: 16           // XS 16 · S 24 · M 40 · L 56
    property string icon: ""
    property bool interactive: true
    property color activeColor: Colors.m3primary
    property color inactiveColor: Colors.m3secondaryContainer
    readonly property bool dragging: mouse.pressed
    signal moved(real value)

    readonly property int handleHeight: trackHeight <= 24 ? 44 : trackHeight + 12
    readonly property real handleWidth: dragging ? 2 : 4
    readonly property int gap: 6
    readonly property real handleX: shown * (width - handleWidth)
    readonly property real outer: trackHeight / 2
    readonly property real inner: Math.min(2, trackHeight / 4)

    // Follows `value` on a live spring; under the finger it tracks exactly.
    property real dragValue: 0
    readonly property real shown: dragging ? dragValue : spring.value
    SpringValue { id: spring; target: root.value; damping: 0.7; stiffness: 520; epsilon: 0.0005 }

    implicitWidth: 200
    implicitHeight: interactive ? handleHeight : trackHeight

    Rectangle {
        id: active
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.handleX - root.gap)
        height: root.trackHeight
        color: root.activeColor
        topLeftRadius: root.outer
        bottomLeftRadius: root.outer
        topRightRadius: root.inner
        bottomRightRadius: root.inner
        visible: width > 0

        Behavior on color { ColorAnim {} }
    }

    Rectangle {
        id: inactive
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX + root.handleWidth + root.gap
        width: Math.max(0, root.width - x)
        height: root.trackHeight
        color: root.inactiveColor
        topLeftRadius: root.inner
        bottomLeftRadius: root.inner
        topRightRadius: root.outer
        bottomRightRadius: root.outer
        visible: width > 0

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: (root.trackHeight - width) / 2
            width: 4
            height: 4
            radius: 2
            color: root.activeColor
            visible: parent.width > root.trackHeight
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX
        width: root.handleWidth
        height: root.interactive ? root.handleHeight : root.trackHeight + 8
        radius: width / 2
        color: root.activeColor

        Behavior on width { SpatialAnim { speed: "fast" } }
    }

    MIcon {
        readonly property bool fits: active.width > root.trackHeight + 4
        visible: root.icon !== "" && root.trackHeight >= 32
        anchors.verticalCenter: parent.verticalCenter
        x: fits ? root.outer - size / 2 + 4 : inactive.x + 10
        icon: root.icon
        size: Math.min(24, root.trackHeight * 0.55)
        fill: 1
        color: fits ? Colors.m3onPrimary : Colors.m3onSecondaryContainer
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function set(x) {
            root.dragValue = Math.max(0, Math.min(1, x / root.width));
            root.moved(root.dragValue);
        }

        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}

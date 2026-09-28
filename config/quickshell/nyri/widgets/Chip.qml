import QtQuick
import qs.theme

Item {
    id: root

    default property alias content: row.data
    property int padding: 10
    property alias spacing: row.spacing
    property alias hovered: layer.containsMouse
    property alias pressed: layer.pressed
    signal clicked(var mouse)
    signal wheel(var event)
    property bool pill: false
    property string segment: "only"
    property color segmentColor: Colors.m3surfaceContainer

    implicitHeight: pill ? 40 : 32

    scale: squish.value
    SpringValue { id: squish; target: layer.pressed ? 0.92 : 1; damping: 0.5; stiffness: 900; epsilon: 0.001 }
    implicitWidth: row.implicitWidth + (pill ? padding + 4 : padding) * 2
    anchors.verticalCenter: parent?.verticalCenter

    SpringValue { id: seg; target: root.pill && (layer.containsMouse || layer.pressed) ? 1 : 0; damping: 0.55; stiffness: 700 }
    readonly property real outer: height / 2
    readonly property real inner: 6 + (height / 2 - 6) * Math.max(0, Math.min(1, seg.value))
    readonly property bool roundLeft: segment === "first" || segment === "only"
    readonly property bool roundRight: segment === "last" || segment === "only"
    Rectangle {
        id: pillBg
        visible: root.pill
        anchors.fill: parent
        topLeftRadius: root.roundLeft ? root.outer : root.inner
        bottomLeftRadius: root.roundLeft ? root.outer : root.inner
        topRightRadius: root.roundRight ? root.outer : root.inner
        bottomRightRadius: root.roundRight ? root.outer : root.inner
        color: root.segmentColor
    }

    StateLayer {
        id: layer
        topLeftRadius: root.pill ? pillBg.topLeftRadius : height / 2
        bottomLeftRadius: root.pill ? pillBg.bottomLeftRadius : height / 2
        topRightRadius: root.pill ? pillBg.topRightRadius : height / 2
        bottomRightRadius: root.pill ? pillBg.bottomRightRadius : height / 2
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: event => root.wheel(event)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}

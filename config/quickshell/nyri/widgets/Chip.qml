import QtQuick
import qs.theme

// Pill-shaped hit target inside an island: content + state layer.
Item {
    id: root

    default property alias content: row.data
    property int padding: 10
    property alias spacing: row.spacing
    property alias hovered: layer.containsMouse
    property alias pressed: layer.pressed
    signal clicked(var mouse)
    signal wheel(var event)

    implicitHeight: 32

    // Press: a small springy squish (M3 Expressive "press" feedback).
    scale: squish.value
    SpringValue { id: squish; target: layer.pressed ? 0.92 : 1; damping: 0.5; stiffness: 900; epsilon: 0.001 }
    implicitWidth: row.implicitWidth + padding * 2
    anchors.verticalCenter: parent?.verticalCenter

    StateLayer {
        id: layer
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

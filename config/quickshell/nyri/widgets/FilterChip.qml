import QtQuick
import Quickshell.Widgets
import qs.theme

// M3 filter chip, Expressive. Picking it: the check mark unfolds in from the
// left on a spring (the chip widens to make room), the outline melts into a
// tonal fill and the corners round into a pill. Pressing squishes it.
// Optional `swatch`: up to three colours shown as a small split dot.
Item {
    id: root

    property string text
    property bool picked: false
    property var swatch: null            // ["#rrggbb", ...] or null
    signal clicked

    SpringValue { id: pickS; target: root.picked ? 1 : 0; damping: 0.62; stiffness: 520 }
    SpringValue { id: squish; target: layer.pressed ? 0.94 : 1; damping: 0.5; stiffness: 900; epsilon: 0.001 }
    readonly property real p: Math.max(0, Math.min(1, pickS.value))

    implicitHeight: 36
    implicitWidth: row.implicitWidth + 28
    scale: squish.value

    Rectangle {
        anchors.fill: parent
        radius: Shape.small + (height / 2 - Shape.small) * root.p
        color: Qt.alpha(Colors.m3secondaryContainer, root.p)
        border.width: 1
        border.color: Qt.alpha(Colors.m3outlineVariant, 1 - root.p)

        StateLayer {
            id: layer
            radius: parent.radius
            color: root.picked ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
            onClicked: root.clicked()
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // The check takes its room only while picked.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 18 * pickS.value
            height: 18
            visible: width > 0.5
            MIcon {
                anchors.centerIn: parent
                icon: "check"
                size: 18
                scale: Math.max(0, pickS.value)
                rotation: (1 - pickS.value) * -60
                color: Colors.m3onSecondaryContainer
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.swatch !== null
            width: 18
            height: 18
            ClippingRectangle {
                anchors.fill: parent
                radius: 9
                color: root.swatch?.[2] ?? "transparent"
                Rectangle { width: 9; height: 18; color: root.swatch?.[0] ?? "transparent" }
                Rectangle { x: 9; y: 9; width: 9; height: 9; color: root.swatch?.[1] ?? "transparent" }
            }
        }

        MText {
            anchors.verticalCenter: parent.verticalCenter
            textStyle: Type.labelLarge
            color: root.picked ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
            text: root.text
        }
    }
}

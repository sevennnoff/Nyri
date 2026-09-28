import QtQuick
import qs.theme
import qs.services
import qs.widgets

Island {
    id: root

    required property string output
    readonly property var list: Niri.workspacesOn(output)

    padding: 14
    spacing: 6

    Repeater {
        model: root.list.length

        Item {
            id: dot

            required property int index
            readonly property var ws: root.list[index]
            readonly property bool active: ws?.is_active ?? false
            readonly property bool urgent: ws?.is_urgent ?? false
            readonly property bool occupied: ws ? Niri.windowCount(ws.id) > 0 : false

            anchors.verticalCenter: parent.verticalCenter
            width: w.value
            height: h.value

            SpringValue { id: w; target: dot.active ? 36 : hit.containsMouse ? 14 : 10; damping: 0.55; stiffness: 700 }
            SpringValue { id: h; target: dot.active ? 12 : 10; damping: 0.55; stiffness: 700 }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: dot.urgent ? Colors.m3error
                     : dot.active ? Colors.m3primary
                     : dot.occupied ? Colors.m3onSurfaceVariant
                     : Colors.m3outlineVariant

                Behavior on color { ColorAnim {} }
            }

            MouseArea {
                id: hit
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.action("focus-workspace", String(dot.ws.idx))
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => Niri.action(event.angleDelta.y < 0 ? "focus-workspace-down" : "focus-workspace-up")
    }
}

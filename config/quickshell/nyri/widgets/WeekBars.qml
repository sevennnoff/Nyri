import QtQuick
import qs.theme

Row {
    id: root

    property var values: []
    property var labels: []
    property int barHeight: 120
    readonly property real peak: Math.max(3600, ...values)

    spacing: 8

    Repeater {
        model: root.values.length

        Column {
            id: col

            required property int index
            readonly property bool today: index === root.values.length - 1
            readonly property real v: root.values[index] ?? 0

            width: (root.width - root.spacing * 6) / 7
            spacing: 6

            Item {
                width: parent.width
                height: root.barHeight

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(28, parent.width)
                    height: Math.max(width, (col.v / root.peak) * root.barHeight)
                    radius: width / 2
                    color: col.today ? Colors.m3primary : Colors.m3secondaryContainer

                    Behavior on height { SpatialAnim {} }
                }
            }

            MText {
                anchors.horizontalCenter: parent.horizontalCenter
                textStyle: col.today ? Type.labelLargeEmph : Type.labelMedium
                color: col.today ? Colors.m3primary : Colors.m3onSurfaceVariant
                text: root.labels[col.index] ?? ""
            }
        }
    }
}

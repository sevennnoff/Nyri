import QtQuick
import qs.theme

// M3 Expressive connected button group: segments share inner corners of 8dp,
// and the selected one grows full-round corners and a check-free fill.
Row {
    id: root

    property var options: []            // [{ value, label, icon? }]
    property var value
    signal selected(var value)

    spacing: 2

    Repeater {
        model: root.options

        Rectangle {
            id: seg

            required property var modelData
            required property int index
            readonly property bool picked: root.value === modelData.value
            readonly property bool first: index === 0
            readonly property bool last: index === root.options.length - 1
            readonly property real outer: height / 2
            readonly property real inner: picked ? height / 2 : Shape.small

            width: (root.width - root.spacing * (root.options.length - 1)) / root.options.length
            height: 40
            color: picked ? Colors.m3primary : Colors.m3surfaceContainerHighest
            topLeftRadius: first ? outer : inner
            bottomLeftRadius: first ? outer : inner
            topRightRadius: last ? outer : inner
            bottomRightRadius: last ? outer : inner

            Behavior on topLeftRadius { SpatialAnim { speed: "fast" } }
            Behavior on bottomLeftRadius { SpatialAnim { speed: "fast" } }
            Behavior on topRightRadius { SpatialAnim { speed: "fast" } }
            Behavior on bottomRightRadius { SpatialAnim { speed: "fast" } }
            Behavior on color { ColorAnim {} }

            Row {
                anchors.centerIn: parent
                spacing: 6

                MIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!seg.modelData.icon
                    icon: seg.modelData.icon ?? ""
                    size: 18
                    fill: seg.picked ? 1 : 0
                    color: seg.picked ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                }

                MText {
                    anchors.verticalCenter: parent.verticalCenter
                    textStyle: Type.labelLarge
                    color: seg.picked ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                    text: seg.modelData.label
                }
            }

            StateLayer {
                topLeftRadius: seg.topLeftRadius
                topRightRadius: seg.topRightRadius
                bottomLeftRadius: seg.bottomLeftRadius
                bottomRightRadius: seg.bottomRightRadius
                color: seg.picked ? Colors.m3onPrimary : Colors.m3onSurface
                onClicked: root.selected(seg.modelData.value)
            }
        }
    }
}

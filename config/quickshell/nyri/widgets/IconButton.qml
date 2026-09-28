import QtQuick
import qs.theme

Item {
    id: root

    property string icon
    property string style: "standard"
    property bool toggle: false
    property bool checked: false
    property int size: 40
    property int iconSize: 22
    readonly property bool hovered: layer.containsMouse
    signal clicked

    readonly property bool active: toggle ? checked : style === "filled"
    readonly property bool tonal: style === "tonal" || (style === "filled" && !active)
    readonly property color fg: active ? Colors.m3onPrimary
                              : tonal ? Colors.m3onSecondaryContainer
                              : Colors.m3onSurfaceVariant
    readonly property color bg: active ? Colors.m3primary
                              : tonal ? Colors.m3secondaryContainer
                              : "transparent"

    implicitWidth: size
    implicitHeight: size

    scale: squish.value
    SpringValue { id: squish; target: layer.pressed ? 0.88 : 1; damping: 0.45; stiffness: 900; epsilon: 0.001 }

    Rectangle {
        id: shape
        anchors.fill: parent
        color: root.bg
        border.width: root.style === "outlined" && !root.active ? 1 : 0
        border.color: Colors.m3outlineVariant
        radius: layer.pressed ? Shape.medium : (root.toggle && root.checked) ? Shape.large : height / 2

        Behavior on radius { SpatialAnim { speed: "fast" } }
        Behavior on color { ColorAnim {} }

        StateLayer {
            id: layer
            radius: shape.radius
            color: root.fg
            onClicked: root.clicked()
        }
    }

    MIcon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        fill: root.active ? 1 : 0
        color: root.fg
    }
}

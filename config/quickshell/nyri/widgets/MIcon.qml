import QtQuick
import qs.theme

// Material Symbols Rounded, driven through its variable axes. `fill` animates,
// which is how M3 marks an icon as selected: outlined -> filled.
//
// The item is exactly size × size with the glyph centred in it. (A bare Text
// is taller than the glyph — the font's line box — so anything laid out
// against it sat off-centre.)
Item {
    id: root

    property string icon
    property real size: 20
    property real fill: 0
    property int weight: 500
    property alias color: glyph.color

    implicitWidth: size
    implicitHeight: size

    Behavior on fill { EffectAnim {} }

    Text {
        id: glyph
        anchors.centerIn: parent
        text: root.icon
        color: Colors.m3onSurfaceVariant
        font.family: Type.iconFamily
        font.pixelSize: root.size
        font.variableAxes: ({ "FILL": root.fill, "wght": root.weight, "opsz": Math.max(20, Math.min(48, root.size)) })
        renderType: Text.NativeRendering

        Behavior on color { ColorAnim {} }
    }
}

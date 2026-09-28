import QtQuick
import qs.theme

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

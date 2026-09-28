import QtQuick
import QtQuick.Window
import qs.theme

Item {
    id: root

    property string icon
    property real size: 20
    property real fill: 0
    property int weight: 500
    property color color: Colors.m3onSurfaceVariant

    implicitWidth: size
    implicitHeight: size

    SpringValue { id: f; target: Math.max(0, Math.min(1, root.fill)); damping: 1; stiffness: 900; epsilon: 0.01 }
    readonly property int opsz: Math.round(Math.max(20, Math.min(48, size)) / 4) * 4
    property color shown: color
    Behavior on shown { ColorAnim {} }

    FontMetrics {
        id: fm
        font.family: Type.iconFamily
        font.pixelSize: Math.round(root.size)
        font.variableAxes: ({ "FILL": 0, "wght": root.weight, "opsz": root.opsz })
    }
    readonly property rect ink: fm.tightBoundingRect(icon)
    readonly property real glyphX: ink.width > 0 ? (width - ink.width) / 2 - ink.x : (width - fm.advanceWidth(icon)) / 2
    readonly property real glyphY: ink.height > 0 ? (height - ink.height) / 2 - fm.ascent - ink.y : (height - fm.height) / 2

    component Glyph: Text {
        property real axisFill: 0
        x: Math.round(root.glyphX * Screen.devicePixelRatio) / Screen.devicePixelRatio
        y: Math.round(root.glyphY * Screen.devicePixelRatio) / Screen.devicePixelRatio
        text: root.icon
        color: root.shown
        font.family: Type.iconFamily
        font.pixelSize: Math.round(root.size)
        font.variableAxes: ({ "FILL": axisFill, "wght": root.weight, "opsz": root.opsz })
        renderType: Text.NativeRendering
    }
    Glyph { axisFill: 0; opacity: 1 - f.value; visible: opacity > 0.01 }
    Glyph { axisFill: 1; opacity: f.value; visible: opacity > 0.01 }
}

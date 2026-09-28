import QtQuick
import qs.theme

Text {
    property var textStyle: Type.bodyMedium

    color: Colors.m3onSurface
    font.family: Type.family
    font.pixelSize: textStyle.size
    font.variableAxes: ({ "wght": textStyle.weight, "ROND": textStyle.rond })
    verticalAlignment: Text.AlignVCenter
    renderType: font.pixelSize >= 32 ? Text.CurveRendering : Text.NativeRendering
    font.hintingPreference: Font.PreferNoHinting

    Behavior on color { ColorAnim {} }
}

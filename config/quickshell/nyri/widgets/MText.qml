import QtQuick
import qs.theme

Text {
    property var textStyle: Type.bodyMedium

    color: Colors.m3onSurface
    font.family: Type.family
    font.pixelSize: textStyle.size
    font.variableAxes: ({ "wght": textStyle.weight, "ROND": textStyle.rond })
    verticalAlignment: Text.AlignVCenter
    // Distance-field text (the Qt default) goes soft and thin at UI sizes.
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferNoHinting

    Behavior on color { ColorAnim {} }
}

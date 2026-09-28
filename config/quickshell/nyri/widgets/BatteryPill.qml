import QtQuick
import Quickshell.Widgets
import qs.theme

ClippingRectangle {
    id: root

    property real level: 0
    property bool charging: false
    property int textSize: 12
    property int textWeight: 800

    readonly property bool low: level <= 0.15 && !charging
    readonly property color fillColor: low ? Colors.m3error : charging ? Colors.m3primary : Colors.m3primary
    readonly property color onFill: low ? Colors.m3onError : charging ? Colors.m3onTertiary : Colors.m3onPrimary
    readonly property string label: Math.round(level * 100) + (textSize > 20 ? "%" : "")

    radius: height / 2
    color: Colors.m3surfaceContainerHighest

    MText {
        anchors.centerIn: parent
        font.pixelSize: root.textSize
        font.variableAxes: ({ "wght": root.textWeight })
        color: Colors.m3onSurface
        text: root.label
    }

    Item {
        width: parent.width * root.level
        height: parent.height
        clip: true

        Behavior on width { SpatialAnim {} }

        Rectangle {
            anchors.fill: parent
            color: root.fillColor

            Behavior on color { ColorAnim {} }
        }

        MText {
            x: (root.width - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: root.textSize
            font.variableAxes: ({ "wght": root.textWeight })
            color: root.onFill
            text: root.label
        }
    }
}

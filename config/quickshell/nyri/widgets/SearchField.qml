import QtQuick
import qs.theme

// M3 search bar: a full pill on the highest container, leading icon, and a
// trailing clear button once there is text.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: "Поиск"
    property string icon: "search"

    implicitHeight: 56
    radius: height / 2
    color: Colors.m3surfaceContainerHighest

    MIcon {
        id: lead
        anchors.verticalCenter: parent.verticalCenter
        x: 18
        icon: root.icon
        size: 24
        color: Colors.m3onSurface
    }

    TextInput {
        id: input
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: lead.right
        anchors.leftMargin: 14
        anchors.right: clear.left
        anchors.rightMargin: 8
        color: Colors.m3onSurface
        selectionColor: Colors.m3primaryContainer
        selectedTextColor: Colors.m3onPrimaryContainer
        font.family: Type.family
        font.pixelSize: 17
        font.variableAxes: ({ "wght": 450, "ROND": 50 })
        clip: true

        MText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !input.text
            text: root.placeholder
            font.pixelSize: 17
            color: Colors.m3onSurfaceVariant
        }
    }

    IconButton {
        id: clear
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        icon: "close"
        opacity: input.text ? 1 : 0
        visible: opacity > 0
        onClicked: input.text = ""

        Behavior on opacity { EffectAnim {} }
    }
}

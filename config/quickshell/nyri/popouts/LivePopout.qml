import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.widgets

Surface {
    id: root

    name: "live"
    keyboard: false

    Popout {
        progress: root.progress
        toX: Math.max(12, Math.min(parent.width - toW - 12, (Panels.anchorW > 0 ? Panels.anchorX + Panels.anchorW / 2 : parent.width / 2) - toW / 2))
        toW: 420
        toH: Math.min(col.implicitHeight + 32, room)
        Behavior on toH { SpatialAnim {} }

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 16
            contentHeight: col.implicitHeight
            clip: true
            Overscroll { flick: flick }

            Column {
                id: col
                width: parent.width
                spacing: 8

                Item {
                    width: parent.width
                    height: 40
                    FlowText {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 4
                        textStyle: Type.titleMediumEmph
                        text: Activities.count ? "Сейчас · " + Activities.count : "Сейчас"
                    }
                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "shield_person"
                        style: Privacy.active ? "filled" : "tonal"
                        onClicked: Panels.open("control", "privacy")
                    }
                }

                Repeater {
                    model: ScriptModel { values: Activities.list; objectProp: "id" }
                    ActivityCard {
                        required property var modelData
                        width: col.width
                        activity: modelData
                    }
                }

                Column {
                    width: parent.width
                    visible: Activities.count === 0
                    spacing: 8
                    topPadding: 8
                    bottomPadding: 8
                    MaterialShape {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64; height: 64
                        shape: "cookie7Sided"
                        color: Colors.m3secondaryContainer
                        MIcon { anchors.centerIn: parent; icon: "bedtime"; size: 28; color: Colors.m3onSecondaryContainer }
                    }
                    MText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        textStyle: Type.bodyMedium
                        color: Colors.m3onSurfaceVariant
                        text: "Ничего не происходит"
                    }
                }
            }
        }
    }
}

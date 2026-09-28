import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.widgets

PanelWindow {
    id: root

    screen: Panels.screen
    visible: Notifs.popups.count > 0 || exitTimer.running
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 12 + 40 + 4; right: 0 }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 400 + 24
    implicitHeight: (screen?.height ?? 1080) - 12 - 40 - 4 - 12
    mask: Region { item: hit }

    Item {
        id: hit
        x: list.x
        y: list.y
        width: list.width
        height: list.contentItem.childrenRect.height
    }

    WlrLayershell.namespace: "nyri-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Timer {
        id: exitTimer
        interval: Motion.emphasizedAccel.duration + 50
    }
    Connections {
        target: Notifs.popups
        function onCountChanged() { if (Notifs.popups.count === 0) exitTimer.restart() }
    }

    ListView {
        id: list

        x: 12
        y: 8
        width: 400
        height: parent.height - y
        spacing: 8
        interactive: false
        model: Notifs.popups

        add: Transition {
            NumberAnimation { property: "x"; from: 420; to: 0; duration: Motion.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.defaultSpatial.curve }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.effects.duration }
        }
        remove: Transition {
            NumberAnimation { property: "x"; to: 420; duration: Motion.emphasizedAccel.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedAccel.curve }
            NumberAnimation { property: "opacity"; to: 0; duration: Motion.emphasizedAccel.duration }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Motion.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.defaultSpatial.curve }
        }

        delegate: Item {
            id: slot

            required property int nid
            readonly property var notif: Notifs.find(nid)

            width: list.width
            height: card.implicitHeight

            NotificationCard {
                id: card

                property real born: 0
                SpatialAnim on born { from: 0; to: 1; speed: "fast" }

                width: parent.width
                height: implicitHeight
                notif: slot.notif
                popup: true
                radius: height / 2 + (Shape.largeIncreased - height / 2) * Math.min(1, born)
                scale: 0.88 + 0.12 * born
                transformOrigin: Item.Right
            }

            HoverHandler { id: hover }

            Timer {
                interval: Notifs.timeoutFor(slot.notif)
                running: interval > 0 && !hover.hovered
                onTriggered: Notifs.hidePopup(slot.nid)
            }
        }
    }
}

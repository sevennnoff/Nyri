import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.theme
import qs.services
import qs.widgets

Card {
    id: root

    required property var notif
    property bool popup: false
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string iconSource: {
        const n = notif;
        if (!n) return "";
        const icon = n.appIcon || DesktopEntries.byId(n.desktopEntry)?.icon || "";
        if (icon.startsWith("/") || icon.startsWith("file:"))
            return icon;
        return icon ? Quickshell.iconPath(icon, "dialog-information") : "";
    }

    implicitHeight: body.implicitHeight + 28
    radius: Shape.largeIncreased
    color: critical ? Colors.m3errorContainer : popup ? Colors.m3surfaceContainerHigh : Colors.m3surfaceContainerHighest
    elevation: popup ? 3 : 0

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const def = root.notif?.actions.find(a => a.identifier === "default");
            if (def) Notifs.invoke(root.notif, def);
        }
    }

    Column {
        id: body
        x: 16
        y: 14
        width: parent.width - 32
        spacing: 10

        Row {
            width: parent.width
            spacing: 12

            Item {
                width: 40
                height: 40

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 20
                    color: Colors.m3secondaryContainer
                    visible: !!root.notif?.image

                    Image {
                        anchors.fill: parent
                        source: root.notif?.image ?? ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(80, 80)
                        asynchronous: true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: Colors.m3secondaryContainer
                    visible: !root.notif?.image

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 24
                        source: root.iconSource
                        visible: root.iconSource !== ""
                    }

                    MIcon {
                        anchors.centerIn: parent
                        visible: root.iconSource === ""
                        icon: "notifications"
                        fill: 1
                        color: Colors.m3onSecondaryContainer
                    }
                }
            }

            Column {
                width: parent.width - 40 - 12 - 36
                spacing: 2

                MText {
                    width: parent.width
                    elide: Text.ElideRight
                    textStyle: Type.labelMedium
                    color: root.critical ? Colors.m3onErrorContainer : Colors.m3onSurfaceVariant
                    text: [root.notif?.appName, Notifs.ago(root.notif?.id)].filter(Boolean).join(" · ")
                }

                MText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textStyle: Type.titleSmall
                    font.variableAxes: ({ "wght": 600 })
                    color: root.critical ? Colors.m3onErrorContainer : Colors.m3onSurface
                    text: root.notif?.summary ?? ""
                }

                MText {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? 4 : 6
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    textStyle: Type.bodyMedium
                    color: root.critical ? Colors.m3onErrorContainer : Colors.m3onSurfaceVariant
                    linkColor: Colors.m3primary
                    onLinkActivated: link => Qt.openUrlExternally(link)
                    text: root.notif?.body ?? ""
                }
            }

            IconButton {
                size: 32
                iconSize: 18
                icon: "close"
                onClicked: root.notif?.dismiss()
            }
        }

        Flow {
            width: parent.width
            spacing: 8
            visible: actions.count > 0

            Repeater {
                id: actions
                model: (root.notif?.actions ?? []).filter(a => a.identifier !== "default" && a.text)

                Rectangle {
                    id: chip

                    required property var modelData

                    height: 36
                    width: label.implicitWidth + 32
                    radius: pressed.pressed ? Shape.medium : height / 2
                    color: Colors.m3secondaryContainer

                    Behavior on radius { SpatialAnim { speed: "fast" } }

                    MText {
                        id: label
                        anchors.centerIn: parent
                        textStyle: Type.labelLarge
                        color: Colors.m3onSecondaryContainer
                        text: chip.modelData.text
                    }

                    StateLayer {
                        id: pressed
                        radius: chip.radius
                        color: Colors.m3onSecondaryContainer
                        onClicked: Notifs.invoke(root.notif, chip.modelData)
                    }
                }
            }
        }
    }
}

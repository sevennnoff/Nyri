import QtQuick
import QtQuick.Dialogs
import qs.theme
import qs.services
import qs.widgets

Rectangle {
    id: root

    readonly property var p: Phone.phone
    readonly property bool on: Phone.reachable
    readonly property real level: (Phone.battery?.charge ?? 0) / 100
    readonly property bool charging: Phone.battery?.charging ?? false
    readonly property bool low: on && level <= 0.15 && !charging
    signal opened

    implicitHeight: 212
    radius: Shape.extraLarge
    color: Colors.m3surfaceContainerHigh

    StateLayer {
        radius: root.radius
        onClicked: root.opened()
    }

    Column {
        id: col
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 32
        spacing: 14

        Item {
            width: parent.width
            height: 64

            MaterialShape {
                id: badge
                width: 64
                height: 64
                shape: root.on ? "cookie9Sided" : "circle"
                color: root.low ? Colors.m3errorContainer : root.on ? Colors.m3primaryContainer : Colors.m3surfaceContainerHighest
                SpringValue { id: turn; target: root.on ? 0 : -40; damping: 0.5; stiffness: 180 }
                rotation: turn.value
                MIcon {
                    anchors.centerIn: parent
                    rotation: -badge.rotation
                    icon: root.on ? "mobile_2" : "mobile_off"
                    size: 30
                    fill: root.on ? 1 : 0
                    color: root.low ? Colors.m3onErrorContainer : root.on ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant
                }
            }

            Column {
                anchors.left: badge.right
                anchors.leftMargin: 16
                anchors.right: pct.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                FlowText {
                    width: parent.width
                    elide: Text.ElideRight
                    textStyle: Type.titleMediumEmph
                    text: root.p?.name ?? "Телефон"
                }
                FlowText {
                    width: parent.width
                    elide: Text.ElideRight
                    textStyle: Type.labelMedium
                    color: Colors.m3onSurfaceVariant
                    text: !root.p ? "Не связан" : !root.on ? "Не в сети"
                        : "На связи"
                }
            }

            Row {
                id: pct
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.on && Phone.battery !== null
                spacing: 2
                MIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.charging
                    icon: "bolt"
                    size: 24
                    fill: 1
                    color: Colors.m3primary
                }
                RollingText {
                    anchors.verticalCenter: parent.verticalCenter
                    pixelSize: 34
                    weight: 650
                    color: root.low ? Colors.m3error : Colors.m3onSurface
                    text: Math.round(root.level * 100) + "%"
                }
            }
        }

        Row {
            height: 32
            spacing: 6
            visible: root.on
            Repeater {
                model: [
                    root.p?.signal ? { icon: "signal_cellular_" + Math.max(0, Math.min(4, root.p.signal.strength ?? 4)) + "_bar", text: root.p.signal.type } : null,
                    Phone.battery ? { icon: root.charging ? "battery_charging_full" : root.low ? "battery_alert" : "battery_full", text: root.charging ? "Заряжается" : "От батареи" } : null
                ].filter(Boolean)
                Rectangle {
                    id: fact
                    required property var modelData
                    required property int index
                    height: 32
                    width: factRow.implicitWidth + 24
                    radius: Shape.small
                    color: Colors.m3surfaceContainerHighest
                    SpringValue { id: factIn; target: root.visible ? 1 : 0; damping: 0.6; stiffness: 360 - fact.index * 60; Component.onCompleted: { value = 0; running = true; } }
                    opacity: Math.max(0, Math.min(1, factIn.value))
                    transform: Translate { x: (1 - factIn.value) * 16 }
                    Row {
                        id: factRow
                        anchors.centerIn: parent
                        spacing: 6
                        MIcon { anchors.verticalCenter: parent.verticalCenter; icon: fact.modelData.icon; size: 16; fill: 1; color: Colors.m3onSurfaceVariant }
                        MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelMedium; color: Colors.m3onSurfaceVariant; text: fact.modelData.text }
                    }
                }
            }
        }
        Item { width: 1; height: 32; visible: !root.on }

        Row {
            id: group
            width: parent.width
            height: 56
            spacing: 3
            enabled: root.on
            opacity: root.on ? 1 : 0.45
            Behavior on opacity { EffectAnim {} }

            readonly property var acts: [
                { icon: "ring_volume", label: "Найти", act: () => Phone.ring() },
                { icon: "upload_file", label: "Файл", act: () => picker.open() },
                { icon: "content_paste_go", label: "Буфер", act: () => Phone.sendClipboard() },
                { icon: "folder_open", label: "Память", act: () => { Panels.close(); Phone.browse(); } }
            ]

            Repeater {
                model: group.acts
                Rectangle {
                    id: seg
                    required property var modelData
                    required property int index
                    readonly property bool first: index === 0
                    readonly property bool last: index === group.acts.length - 1
                    width: (group.width - group.spacing * (group.acts.length - 1)) / group.acts.length
                    height: group.height
                    SpringValue { id: r; target: segLayer.pressed || segLayer.containsMouse ? 1 : 0; damping: 0.55; stiffness: 700 }
                    readonly property real inner: 8 + (height / 2 - 8) * Math.max(0, Math.min(1, r.value))
                    topLeftRadius: first ? height / 2 : inner
                    bottomLeftRadius: first ? height / 2 : inner
                    topRightRadius: last ? height / 2 : inner
                    bottomRightRadius: last ? height / 2 : inner
                    color: Colors.m3secondaryContainer
                    scale: pop.value
                    SpringValue { id: pop; target: 1; damping: 0.4; stiffness: 700; epsilon: 0.001 }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        MIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: seg.modelData.icon; size: 20; fill: 1; color: Colors.m3onSecondaryContainer }
                        MText { anchors.horizontalCenter: parent.horizontalCenter; textStyle: Type.labelMedium; color: Colors.m3onSecondaryContainer; text: seg.modelData.label }
                    }
                    StateLayer {
                        id: segLayer
                        topLeftRadius: seg.topLeftRadius
                        bottomLeftRadius: seg.bottomLeftRadius
                        topRightRadius: seg.topRightRadius
                        bottomRightRadius: seg.bottomRightRadius
                        color: Colors.m3onSecondaryContainer
                        onClicked: { pop.value = 0.9; pop.running = true; seg.modelData.act(); }
                    }
                }
            }
        }
    }

    FileDialog {
        id: picker
        title: "Отправить на телефон"
        fileMode: FileDialog.OpenFiles
        onAccepted: { for (const f of selectedFiles) Phone.share(f.toString()); }
    }
}

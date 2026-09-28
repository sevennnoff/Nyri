import QtQuick
import QtQuick.Dialogs
import qs.theme
import qs.services
import qs.widgets

Rectangle {
    id: root

    readonly property var p: Phone.phone
    readonly property bool on: Phone.reachable
    signal opened

    implicitHeight: 148
    radius: Shape.extraLarge
    color: on ? Colors.m3primaryContainer : Colors.m3surfaceContainerHigh
    Behavior on color { ColorAnim {} }
    readonly property color ink: on ? Colors.m3onPrimaryContainer : Colors.m3onSurface
    readonly property color soft: on ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant

    StateLayer {
        radius: root.radius
        color: root.ink
        onClicked: root.opened()
    }

    Item {
        id: slab
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        width: 58
        height: 104
        SpringValue { id: tilt; target: root.on ? -8 : 0; damping: 0.5; stiffness: 160 }
        rotation: tilt.value

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: root.on ? Colors.m3primary : Colors.m3surfaceContainerHighest
            Behavior on color { ColorAnim {} }
        }
        Rectangle {
            x: 5
            width: parent.width - 10
            SpringValue { id: charge; target: (Phone.battery?.charge ?? 0) / 100; damping: 0.8; stiffness: 90 }
            height: Math.max(0, (parent.height - 10) * charge.value)
            y: parent.height - 5 - height
            radius: 12
            color: root.on ? Qt.alpha(Colors.m3onPrimary, 0.28) : "transparent"
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 8
            width: 16
            height: 4
            radius: 2
            color: root.on ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
            opacity: 0.6
        }
        MIcon {
            anchors.centerIn: parent
            visible: Phone.battery?.charging ?? false
            icon: "bolt"
            size: 26
            fill: 1
            color: Colors.m3onPrimary
        }
    }

    Column {
        anchors.left: slab.right
        anchors.leftMargin: 22
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: 18
        spacing: 2

        FlowText {
            width: parent.width
            elide: Text.ElideRight
            textStyle: Type.titleMediumEmph
            color: root.ink
            text: root.p?.name ?? "Телефон"
        }
        FlowText {
            width: parent.width
            elide: Text.ElideRight
            textStyle: Type.labelMedium
            color: root.soft
            text: !root.p ? "Не связан" : !root.on ? "Не в сети"
                : (Phone.battery ? Phone.battery.charge + "%" + (Phone.battery.charging ? " · заряжается" : "") : "На связи")
                  + (root.p.signal ? " · " + root.p.signal.type : "")
        }
    }

    Row {
        anchors.left: slab.right
        anchors.leftMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        spacing: 6
        enabled: root.on
        opacity: root.on ? 1 : 0.45
        Behavior on opacity { EffectAnim {} }

        Repeater {
            model: [
                { icon: "ring_volume", act: () => Phone.ring() },
                { icon: "upload_file", act: () => picker.open() },
                { icon: "content_paste_go", act: () => Phone.sendClipboard() },
                { icon: "folder_open", act: () => { Panels.close(); Phone.browse(); } }
            ]
            Rectangle {
                id: btn
                required property var modelData
                width: 48
                height: 48
                radius: btnLayer.pressed ? Shape.medium : height / 2
                color: root.on ? Colors.m3primary : Colors.m3surfaceContainerHighest
                Behavior on radius { SpatialAnim { speed: "fast" } }
                scale: pop.value
                SpringValue { id: pop; target: 1; damping: 0.4; stiffness: 700; epsilon: 0.001 }
                MIcon { anchors.centerIn: parent; icon: btn.modelData.icon; size: 22; fill: 1; color: root.on ? Colors.m3onPrimary : Colors.m3onSurfaceVariant }
                StateLayer {
                    id: btnLayer
                    radius: btn.radius
                    color: Colors.m3onPrimary
                    onClicked: { pop.value = 0.85; pop.running = true; btn.modelData.act(); }
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

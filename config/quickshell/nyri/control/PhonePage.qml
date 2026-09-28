import QtQuick
import QtQuick.Dialogs
import Quickshell
import qs.theme
import qs.services
import qs.widgets

Column {
    id: root

    signal back
    spacing: 16

    readonly property var p: Phone.phone

    PageHeader {
        title: root.p?.name ?? "Телефон"
        onBack: root.back()
    }

    Rectangle {
        width: root.width
        height: 132
        radius: Shape.extraLarge
        color: Phone.reachable ? Colors.m3primaryContainer : Colors.m3surfaceContainerHigh
        Behavior on color { ColorAnim {} }

        MaterialShape {
            id: phoneShape
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 88
            height: 88
            shape: Phone.reachable ? "cookie12Sided" : "circle"
            color: Phone.reachable ? Colors.m3primary : Colors.m3surfaceContainerHighest
            SpringValue { id: spin; target: Phone.reachable ? 0 : -45; damping: 0.55; stiffness: 200 }
            rotation: spin.value
            MIcon {
                anchors.centerIn: parent
                rotation: -phoneShape.rotation
                icon: root.p?.type === "tablet" ? "tablet_android" : "smartphone"
                size: 40
                fill: 1
                color: Phone.reachable ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
            }
        }

        Column {
            anchors.left: phoneShape.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            FlowText {
                width: parent.width
                elide: Text.ElideRight
                textStyle: Type.titleLarge
                color: Phone.reachable ? Colors.m3onPrimaryContainer : Colors.m3onSurface
                text: !Phone.daemon ? "KDE Connect не запущен"
                    : !root.p ? "Телефон не связан"
                    : Phone.reachable ? "На связи" : "Не в сети"
            }
            BatteryPill {
                visible: Phone.battery !== null
                size: 18
                textSize: 16
                level: (Phone.battery?.charge ?? 0) / 100
                charging: Phone.battery?.charging ?? false
                color: Colors.m3onPrimaryContainer
            }
            MText {
                visible: text !== ""
                width: parent.width
                wrapMode: Text.Wrap
                textStyle: Type.labelMedium
                color: Phone.reachable ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant
                text: Phone.reachable && root.p?.signal ? "Сеть " + root.p.signal.type
                    : !Phone.daemon ? "Запусти kdeconnectd или поставь kdeconnect"
                    : !root.p ? "Открой KDE Connect на телефоне и сопряги его с этим ноутбуком"
                    : !Phone.reachable ? "Телефон и ноутбук должны быть в одной сети" : ""
            }
        }
    }

    component Action: Rectangle {
        id: act
        property string icon
        property string label
        property string sub: ""
        property bool first: false
        property bool last: false
        signal clicked
        width: root.width
        height: 72
        readonly property real big: Shape.large
        SpringValue { id: roundOff; target: actLayer.containsMouse ? 1 : 0; damping: 0.6; stiffness: 600 }
        readonly property real inner: 4 + (big - 4) * Math.max(0, Math.min(1, roundOff.value))
        topLeftRadius: first ? big : inner
        topRightRadius: first ? big : inner
        bottomLeftRadius: last ? big : inner
        bottomRightRadius: last ? big : inner
        color: Colors.m3surfaceContainerHigh
        opacity: enabled ? 1 : 0.45
        scale: sq.value * pop.value
        SpringValue { id: sq; target: actLayer.pressed ? 0.97 : 1; damping: 0.5; stiffness: 800; epsilon: 0.001 }
        SpringValue { id: pop; target: 1; damping: 0.4; stiffness: 600; epsilon: 0.001 }
        Row {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            width: parent.width - 32
            MaterialShape {
                anchors.verticalCenter: parent.verticalCenter
                width: 44; height: 44
                shape: "cookie9Sided"
                color: Colors.m3secondaryContainer
                MIcon { anchors.centerIn: parent; icon: act.icon; size: 22; fill: 1; color: Colors.m3onSecondaryContainer }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 56 - 24
                spacing: 2
                MText { width: parent.width; elide: Text.ElideRight; textStyle: Type.titleSmall; text: act.label }
                MText { width: parent.width; visible: text !== ""; elide: Text.ElideRight; textStyle: Type.bodySmall; color: Colors.m3onSurfaceVariant; text: act.sub }
            }
        }
        MIcon {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            icon: "chevron_right"
            size: 20
            color: Colors.m3onSurfaceVariant
            opacity: actLayer.containsMouse ? 1 : 0.5
            transform: Translate { x: nudge.value }
            SpringValue { id: nudge; target: actLayer.containsMouse ? 4 : 0; damping: 0.55; stiffness: 600 }
        }
        StateLayer {
            id: actLayer
            topLeftRadius: act.topLeftRadius
            topRightRadius: act.topRightRadius
            bottomLeftRadius: act.bottomLeftRadius
            bottomRightRadius: act.bottomRightRadius
            onClicked: { pop.value = 0.9; pop.running = true; act.clicked(); }
        }
    }

    Column {
        width: root.width
        spacing: 4
        enabled: Phone.reachable

        Action { first: true; icon: "ring_volume"; label: "Найти телефон"; sub: "Позвонит на полную"; onClicked: Phone.ring() }
        Action { icon: "upload_file"; label: "Отправить файл"; sub: "Попадёт в загрузки"; onClicked: picker.open() }
        Action { icon: "content_paste_go"; label: "Отправить буфер"; sub: "Что скопировано здесь"; onClicked: Phone.sendClipboard() }
        Action { last: true; icon: "folder_open"; label: "Файлы телефона"; sub: "Открыть его память"; onClicked: { Panels.close(); Phone.browse(); } }
    }

    FileDialog {
        id: picker
        title: "Отправить на телефон"
        fileMode: FileDialog.OpenFiles
        onAccepted: { for (const f of selectedFiles) Phone.share(f.toString()); }
    }

    ListGroup {
        width: root.width
        title: "Хотят связаться"
        visible: Phone.requests.length > 0
        Repeater {
            model: Phone.requests
            SettingRow {
                required property var modelData
                icon: "smartphone"
                title: modelData.name
                subtitle: "Просит сопряжения"
                IconButton { icon: "check"; style: "filled"; size: 36; iconSize: 18; onClicked: Phone.accept(parent.parent.modelData.id) }
            }
        }
    }

    Item {
        width: root.width
        height: 40
        Chip {
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: { Panels.close(); Phone.openApp(); }
            MIcon { anchors.verticalCenter: parent.verticalCenter; icon: "settings"; size: 18; color: Colors.m3primary }
            MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLarge; color: Colors.m3primary; text: "KDE Connect" }
        }
    }
}

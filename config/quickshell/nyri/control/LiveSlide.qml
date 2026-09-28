import QtQuick
import qs.theme
import qs.services
import qs.widgets

Rectangle {
    id: root

    required property var activity
    readonly property var a: activity
    readonly property string kind: a?.kind ?? ""
    readonly property bool loud: a?.tone === "error"

    implicitHeight: 212
    radius: Shape.extraLarge
    color: loud ? Colors.m3errorContainer : Colors.m3surfaceContainerHigh
    Behavior on color { ColorAnim {} }
    readonly property color ink: loud ? Colors.m3onErrorContainer : Colors.m3onSurface
    readonly property color soft: loud ? Colors.m3onErrorContainer : Colors.m3onSurfaceVariant

    property real now: Date.now()
    Timer {
        running: root.visible && (root.a?.until > 0 || root.a?.since > 0)
        interval: root.kind === "stopwatch" ? 100 : 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }
    function clock(ms, tenths) {
        const s = Math.max(0, Math.floor(ms / 1000)), h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60;
        const main = (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(r).padStart(2, "0");
        return tenths ? main + "." + Math.floor(Math.max(0, ms) % 1000 / 100) : main;
    }
    readonly property real remaining: (a?.frozen ?? -1) >= 0 ? a.frozen : a?.until > 0 ? a.until - now : 0
    readonly property real ran: (a?.frozen ?? -1) >= 0 ? a.frozen : a?.since > 0 ? now - a.since : 0

    StateLayer {
        radius: root.radius
        color: root.ink
        enabled: root.kind.indexOf("-idle") < 0
        onClicked: Activities.open(root.a)
    }

    component Actions: Row {
        property bool iconsOnly: false
        id: actRow
        spacing: 8
        Repeater {
            model: root.a?.actions ?? []
            Rectangle {
                id: btn
                required property var modelData
                height: actRow.iconsOnly ? 52 : 44
                width: actRow.iconsOnly ? 52 : btnRow.implicitWidth + 28
                radius: btnLayer.pressed ? Shape.medium : height / 2
                color: root.loud ? Colors.m3error : Colors.m3secondaryContainer
                Behavior on radius { SpatialAnim { speed: "fast" } }
                scale: pop.value
                SpringValue { id: pop; target: 1; damping: 0.4; stiffness: 700; epsilon: 0.001 }
                Row {
                    id: btnRow
                    anchors.centerIn: parent
                    spacing: 6
                    MIcon { anchors.verticalCenter: parent.verticalCenter; icon: btn.modelData.icon; size: 20; fill: 1; color: root.loud ? Colors.m3onError : Colors.m3onSecondaryContainer }
                    MText { anchors.verticalCenter: parent.verticalCenter; visible: !actRow.iconsOnly; textStyle: Type.labelLargeEmph; color: root.loud ? Colors.m3onError : Colors.m3onSecondaryContainer; text: btn.modelData.label }
                }
                StateLayer {
                    id: btnLayer
                    radius: btn.radius
                    color: root.loud ? Colors.m3onError : Colors.m3onSecondaryContainer
                    onClicked: { pop.value = 0.88; pop.running = true; Activities.act(root.a.id, btn.modelData.key); }
                }
            }
        }
    }

    component Face: Item {
        id: face
        property bool on: false
        anchors.fill: parent
        SpringValue { id: fv; target: face.on ? 1 : 0; damping: 0.72; stiffness: 360; epsilon: 0.002 }
        readonly property real v: Math.max(0, fv.value)
        visible: v > 0.01
        opacity: Math.min(1, v * v * 1.2)
        scale: 0.92 + 0.08 * v
    }

    Face {
        on: root.kind === "timer"

        Item {
            id: ring
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 168
            height: 168
            SpringValue { id: ringV; target: root.kind === "timer" ? 1 - Math.max(0, Math.min(1, root.a?.progress ?? 0)) : 0; damping: 1; stiffness: 60; epsilon: 0.0005 }
            CircularProgress {
                anchors.fill: parent
                stroke: 12
                value: ringV.value
                animated: false
                activeColor: Colors.m3primary
            }
            Column {
                anchors.centerIn: parent
                MText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 38
                    font.variableAxes: ({ "wght": 650 })
                    font.features: { "tnum": 1 }
                    color: root.ink
                    text: root.clock(root.remaining, false)
                }
                MText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    textStyle: Type.labelMedium
                    color: root.soft
                    text: (root.a?.frozen ?? -1) >= 0 ? "на паузе" : "осталось"
                }
            }
        }

        Column {
            anchors.left: ring.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 24
            spacing: 4
            MText { width: parent.width; elide: Text.ElideRight; textStyle: Type.titleLarge; color: root.ink; text: root.a?.title ?? "" }
            MText {
                width: parent.width
                wrapMode: Text.Wrap
                textStyle: Type.bodyMedium
                color: root.soft
                text: (root.a?.frozen ?? -1) >= 0 ? "Стоит" : "Прозвенит в " + Qt.formatTime(new Date(root.a?.until ?? 0), "HH:mm")
                      + (root.a?.text ? " · " + root.a.text : "")
            }
        }
        Actions {
            iconsOnly: true
            anchors.left: ring.right
            anchors.leftMargin: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 22
        }
    }

    Face {
        on: root.kind === "stopwatch"

        Column {
            x: 24
            y: 22
            spacing: 2
            MText { textStyle: Type.labelLargeEmph; color: Colors.m3primary; text: "Секундомер" }
            MText {
                font.pixelSize: 56
                font.variableAxes: ({ "wght": 650 })
                font.features: { "tnum": 1 }
                color: root.ink
                text: root.clock(root.ran, true)
            }
        }
        Column {
            anchors.right: parent.right
            anchors.rightMargin: 24
            y: 28
            spacing: 4
            Repeater {
                model: (Activities.stopwatch?.laps ?? []).slice(0, 3)
                Row {
                    required property var modelData
                    required property int index
                    spacing: 8
                    MText { textStyle: Type.labelMedium; color: root.soft; text: "Круг " + ((Activities.stopwatch?.laps.length ?? 0) - index) }
                    MText { textStyle: Type.labelLargeEmph; font.features: { "tnum": 1 }; color: root.ink; text: root.clock(modelData, true) }
                }
            }
        }
        Actions {
            x: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
        }
    }

    Face {
        on: ["timer", "stopwatch", "timer-idle", "stopwatch-idle"].indexOf(root.kind) < 0

        MaterialShape {
            id: shape
            x: 20
            y: 20
            width: 72
            height: 72
            shape: root.loud ? "softBurst" : "cookie9Sided"
            color: root.loud ? Colors.m3error : Colors.m3primaryContainer
            MIcon { anchors.centerIn: parent; icon: root.a?.icon ?? ""; size: 34; fill: 1; color: root.loud ? Colors.m3onError : Colors.m3onPrimaryContainer }
        }
        Column {
            anchors.left: shape.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 20
            y: 26
            spacing: 2
            MText { width: parent.width; elide: Text.ElideRight; textStyle: Type.titleMediumEmph; color: root.ink; text: root.a?.title ?? "" }
            MText { width: parent.width; elide: Text.ElideRight; textStyle: Type.bodyMedium; color: root.soft; text: root.a?.text ?? "" }
            MText {
                visible: text !== ""
                textStyle: Type.titleMediumEmph
                font.features: { "tnum": 1 }
                color: root.loud ? Colors.m3error : Colors.m3primary
                text: root.a?.since > 0 ? root.clock(root.ran, false) : root.a?.until > 0 ? root.clock(root.remaining, false) : ""
            }
        }
        WavyProgress {
            x: 20
            y: 110
            width: parent.width - 40
            height: 20
            visible: (root.a?.progress ?? -1) >= 0 || root.a?.progress === -2
            value: (root.a?.progress ?? -1) >= 0 ? root.a.progress : 0.35
            wavy: true
            flowing: root.visible
            activeColor: root.loud ? Colors.m3onErrorContainer : Colors.m3primary
        }
        Actions {
            x: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
        }
    }

    Face {
        on: root.kind === "timer-idle"

        Item {
            id: idleRing
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 168
            height: 168
            CircularProgress { anchors.fill: parent; stroke: 12; value: 0; animated: false }
            MIcon { anchors.centerIn: parent; icon: "timer"; size: 56; color: Colors.m3onSurfaceVariant }
        }
        Column {
            anchors.left: idleRing.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            MText { textStyle: Type.titleLarge; color: root.ink; text: "Таймер" }
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: [1, 5, 10, 25]
                    FilterChip {
                        required property int modelData
                        text: modelData + " мин"
                        picked: false
                        onClicked: Activities.addTimer(modelData * 60, "")
                    }
                }
                FilterChip {
                    text: "Свой…"
                    picked: false
                    onClicked: { Panels.prefill = "таймер "; Panels.open("launcher"); }
                }
            }
        }
    }

    Face {
        on: root.kind === "stopwatch-idle"

        Column {
            x: 24
            y: 22
            spacing: 2
            MText { textStyle: Type.labelLargeEmph; color: Colors.m3primary; text: "Секундомер" }
            MText {
                font.pixelSize: 56
                font.variableAxes: ({ "wght": 650 })
                font.features: { "tnum": 1 }
                color: root.soft
                opacity: 0.6
                text: "0:00.0"
            }
        }
        Rectangle {
            id: startBtn
            x: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            width: startRow.implicitWidth + 36
            height: 52
            radius: startLayer.pressed ? Shape.medium : height / 2
            color: Colors.m3primary
            Behavior on radius { SpatialAnim { speed: "fast" } }
            Row {
                id: startRow
                anchors.centerIn: parent
                spacing: 8
                MIcon { anchors.verticalCenter: parent.verticalCenter; icon: "play_arrow"; size: 22; fill: 1; color: Colors.m3onPrimary }
                MText { anchors.verticalCenter: parent.verticalCenter; textStyle: Type.labelLargeEmph; color: Colors.m3onPrimary; text: "Старт" }
            }
            StateLayer { id: startLayer; radius: startBtn.radius; color: Colors.m3onPrimary; onClicked: Activities.startStopwatch() }
        }
    }
}

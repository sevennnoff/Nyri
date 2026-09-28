import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.widgets

Surface {
    id: root

    name: "snip"

    readonly property var actions: [
        { id: "screenshot", icon: "screenshot_region", label: "Снимок", hint: "Выделите область — снимок в буфер и в Картинки" },
        { id: "edit", icon: "draw", label: "Нарисовать", hint: "Выделите область — откроется в Swappy" },
        { id: "ocr", icon: "text_select_start", label: "Текст", hint: "Выделите область — текст скопируется" },
        { id: "search", icon: "image_search", label: "Lens", hint: "Выделите область — поиск в Google Lens" },
        { id: "record", icon: "videocam", label: "Запись", hint: "Выделите область — начнётся запись" },
        { id: "recordWithSound", icon: "mic", label: "Со звуком", hint: "Выделите область — запись со звуком" }
    ]
    readonly property var groupEnds: [1, 3]
    property int current: 0

    property real x0: 0
    property real y0: 0
    property real x1: 0
    property real y1: 0
    property bool dragging: false
    readonly property real selX: Math.min(x0, x1)
    readonly property real selY: Math.min(y0, y1)
    readonly property real selW: Math.abs(x1 - x0)
    readonly property real selH: Math.abs(y1 - y0)
    readonly property bool hasSel: selW > 1 && selH > 1

    function run(geomX, geomY, geomW, geomH) {
        const s = Panels.screen;
        const geom = Math.round((s?.x ?? 0) + geomX) + "," + Math.round((s?.y ?? 0) + geomY)
                   + " " + Math.round(geomW) + "x" + Math.round(geomH);
        go.cmd = [Quickshell.env("HOME") + "/nyri/bin/nyri", "region", actions[current].id, geom];
        root.hidden = true;
        Panels.close();
        go.restart();
    }
    function runFull() { run(0, 0, root.width, root.height); }

    Timer {
        id: go
        property var cmd: []
        interval: 140
        onTriggered: Quickshell.execDetached(cmd)
    }

    onOpenChanged: {
        if (!open) return;
        hidden = false;
        dragging = false;
        x0 = y0 = x1 = y1 = 0;
        keys.forceActiveFocus();
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const n = parseInt(event.text);
            if (n >= 1 && n <= root.actions.length) root.current = n - 1;
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.current = (root.current + 1) % root.actions.length;
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.current = (root.current + root.actions.length - 1) % root.actions.length;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.runFull();
            else return;
            event.accepted = true;
        }
    }

    Item {
        id: dim
        anchors.fill: parent
        opacity: root.fade
        readonly property color shade: Qt.alpha(Colors.m3scrim, 0.45)

        Rectangle { x: 0; y: 0; width: parent.width; height: root.hasSel ? root.selY : parent.height; color: dim.shade }
        Rectangle { visible: root.hasSel; x: 0; y: root.selY; width: root.selX; height: root.selH; color: dim.shade }
        Rectangle { visible: root.hasSel; x: root.selX + root.selW; y: root.selY; width: parent.width - x; height: root.selH; color: dim.shade }
        Rectangle { visible: root.hasSel; x: 0; y: root.selY + root.selH; width: parent.width; height: parent.height - y; color: dim.shade }

        Rectangle {
            visible: root.hasSel
            x: root.selX - 1
            y: root.selY - 1
            width: root.selW + 2
            height: root.selH + 2
            color: "transparent"
            radius: 4
            border.width: 2
            border.color: Colors.m3primary
        }
        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            Rectangle {
                required property var modelData
                visible: root.hasSel
                width: 12
                height: 12
                radius: 6
                x: root.selX + root.selW * modelData[0] - 6
                y: root.selY + root.selH * modelData[1] - 6
                color: Colors.m3primary
                border.width: 2
                border.color: Colors.m3onPrimary
            }
        }
        Rectangle {
            visible: root.hasSel && root.selW > 40
            x: root.selX
            y: root.selY > 44 ? root.selY - 40 : root.selY + 8
            width: sizeText.implicitWidth + 20
            height: 30
            radius: 15
            color: Colors.m3inverseSurface
            MText {
                id: sizeText
                anchors.centerIn: parent
                textStyle: Type.labelLargeEmph
                font.features: { "tnum": 1 }
                color: Colors.m3inverseOnSurface
                text: Math.round(root.selW) + " × " + Math.round(root.selH)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onPressed: m => { root.x0 = root.x1 = m.x; root.y0 = root.y1 = m.y; root.dragging = true; }
        onPositionChanged: m => { if (pressed) { root.x1 = m.x; root.y1 = m.y; } }
        onReleased: {
            root.dragging = false;
            if (root.selW >= 6 && root.selH >= 6) root.run(root.selX, root.selY, root.selW, root.selH);
            else root.x0 = root.y0 = root.x1 = root.y1 = 0;
        }
    }

    Item {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        width: toolbar.width + 12 + fab.width
        height: 64
        y: parent.height - height - 32 + (1 - root.progress) * 96
        opacity: root.fade * (root.dragging ? 0.35 : 1)
        Behavior on opacity { EffectAnim {} }

        Rectangle {
            id: hint
            anchors.horizontalCenter: toolbar.horizontalCenter
            anchors.bottom: toolbar.top
            anchors.bottomMargin: 12
            width: hintText.implicitWidth + 32
            height: 36
            radius: height / 2
            color: Colors.m3inverseSurface
            opacity: Math.max(0, Math.min(1, root.progress * 2 - 1))

            FlowText {
                id: hintText
                anchors.centerIn: parent
                textStyle: Type.labelLarge
                color: Colors.m3inverseOnSurface
                text: root.actions[root.current].hint
            }
        }

        Card {
            id: toolbar
            width: row.width + 16
            height: 64
            radius: height / 2
            color: Colors.m3surfaceContainerHigh
            elevation: 3

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: root.actions

                    Row {
                        id: slot
                        required property var modelData
                        required property int index
                        spacing: 4

                        Item {
                            id: tool
                            readonly property bool on: root.current === slot.index

                            SpringValue { id: grow; target: tool.on ? 1 : 0; damping: 0.62; stiffness: 700 }
                            readonly property real g: Math.max(0, grow.value)
                            readonly property real enter: Math.max(0, Math.min(1, root.progress * 1.6 - slot.index * 0.08))

                            width: 48 + (label.implicitWidth + 10) * grow.value
                            height: 48
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: enter
                            transform: Translate { y: (1 - tool.enter) * 14 }

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colors.m3primary
                                opacity: tool.g
                            }
                            StateLayer {
                                radius: height / 2
                                color: tool.on ? Colors.m3onPrimary : Colors.m3onSurface
                                onClicked: root.current = slot.index
                            }
                            Item {
                                anchors.fill: parent
                                clip: true
                                MIcon {
                                    x: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: slot.modelData.icon
                                    size: 24
                                    fill: tool.g
                                    color: tool.on ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                                }
                                MText {
                                    id: label
                                    x: 42
                                    anchors.verticalCenter: parent.verticalCenter
                                    textStyle: Type.labelLargeEmph
                                    color: Colors.m3onPrimary
                                    opacity: Math.max(0, Math.min(1, grow.value * 1.6 - 0.5))
                                    text: slot.modelData.label
                                }
                            }
                        }

                        Rectangle {
                            visible: root.groupEnds.indexOf(slot.index) >= 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 24
                            color: Colors.m3outlineVariant
                        }
                    }
                }
            }
        }

        Card {
            id: fab
            anchors.right: parent.right
            anchors.verticalCenter: toolbar.verticalCenter
            width: 64
            height: 64
            radius: fabLayer.pressed ? Shape.medium : Shape.large
            color: Colors.m3primaryContainer
            elevation: 3
            scale: 0.4 + 0.6 * Math.max(0, Math.min(1, root.progress * 1.5 - 0.3))
            Behavior on radius { SpatialAnim { speed: "fast" } }

            MIcon {
                anchors.centerIn: parent
                icon: "fullscreen"
                size: 28
                fill: 1
                color: Colors.m3onPrimaryContainer
            }
            StateLayer {
                id: fabLayer
                radius: fab.radius
                color: Colors.m3onPrimaryContainer
                onClicked: root.runFull()
            }
        }
    }
}

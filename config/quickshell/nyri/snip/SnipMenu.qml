import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.widgets

// Ctrl+Shift+S: what to do with a piece of the screen. An M3 Expressive
// floating toolbar at the bottom edge with a FAB beside it: icon buttons in
// three groups, the picked one unfolds into a labelled pill, the FAB runs it.
// Mouse, ←/→, digits 1–7, Enter. The toolbar leaves before the capture
// starts, so it never ends up in the shot.
Surface {
    id: root

    name: "snip"
    scrimOpacity: 0.2

    readonly property var actions: [
        { id: "screenshot", icon: "screenshot_region", label: "Область", hint: "Выделить область — в буфер и в Картинки" },
        { id: "full", icon: "fullscreen", label: "Весь экран", hint: "Снимок всего экрана — в буфер и в Картинки" },
        { id: "edit", icon: "draw", label: "Нарисовать", hint: "Выделить область и подписать в Swappy" },
        { id: "ocr", icon: "text_select_start", label: "Текст", hint: "Распознать текст в области и скопировать" },
        { id: "search", icon: "image_search", label: "Lens", hint: "Найти область в Google Lens" },
        { id: "record", icon: "videocam", label: "Запись", hint: "Записать область экрана" },
        { id: "recordWithSound", icon: "mic", label: "Со звуком", hint: "Записать область вместе со звуком" }
    ]
    // Where the thin dividers go: after "Нарисовать" and after "Lens".
    readonly property var groupEnds: [2, 4]
    property int current: 0

    function run(i) {
        const a = actions[i];
        Panels.close();
        go.cmd = [Quickshell.env("HOME") + "/nyri/bin/nyri", "region", a.id];
        go.restart();
    }

    Timer {
        id: go
        property var cmd: []
        interval: 280
        onTriggered: Quickshell.execDetached(cmd)
    }

    onOpenChanged: if (open) { current = 0; keys.forceActiveFocus(); }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const n = parseInt(event.text);
            if (n >= 1 && n <= root.actions.length) root.current = n - 1;
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.current = (root.current + 1) % root.actions.length;
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.current = (root.current + root.actions.length - 1) % root.actions.length;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.run(root.current);
            else return;
            event.accepted = true;
        }
    }

    Item {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        width: toolbar.width + 12 + fab.width
        height: 64
        y: parent.height - height - 32 + (1 - root.progress) * 96
        opacity: root.fade

        // What the picked action does, riding above the toolbar.
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

                            // Unfold into a labelled pill on a real spring, so a
                            // quick ←→ run hands width from one button to the next.
                            SpringValue { id: grow; target: tool.on ? 1 : 0; damping: 0.62; stiffness: 700 }
                            readonly property real g: Math.max(0, grow.value)

                            // Everything rises in, left to right, as the bar opens.
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
                                onEntered: root.current = slot.index
                                onClicked: root.run(slot.index)
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

        // FAB: shoot with whatever is picked. Morphs its shape on press.
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
                icon: root.actions[root.current].id.startsWith("record") ? "radio_button_checked" : "photo_camera"
                size: 28
                fill: 1
                color: Colors.m3onPrimaryContainer
            }

            StateLayer {
                id: fabLayer
                radius: fab.radius
                color: Colors.m3onPrimaryContainer
                onClicked: root.run(root.current)
            }
        }
    }
}

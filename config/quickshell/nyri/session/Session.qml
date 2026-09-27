import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.widgets

// Power menu. Every action is a shape; the selected one springs into its own
// expressive shape and turns primary. ← → / Tab to move, Enter, or the letter.
Surface {
    id: root

    name: "session"
    scrimOpacity: 0.55

    property int current: 0

    readonly property var actions: [
        { key: "L", label: "Блокировка",  icon: "lock",               shape: "cookie9Sided", run: () => Lock.lock() },
        { key: "S", label: "Сон",         icon: "bedtime",            shape: "clover4Leaf",  run: () => { Lock.lock(); system(["systemctl", "suspend"]); } },
        { key: "E", label: "Выйти",       icon: "logout",             shape: "sunny",        run: () => Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]) },
        { key: "R", label: "Перезагрузка", icon: "restart_alt",       shape: "cookie12Sided", run: () => system(["systemctl", "reboot"]) },
        { key: "P", label: "Выключение",  icon: "power_settings_new", shape: "softBurst",    run: () => system(["systemctl", "poweroff"]) }
    ]

    // Never power off the real laptop from the test window.
    function system(cmd) {
        if (Panels.nested)
            console.log("nested: skipped", cmd.join(" "));
        else
            Quickshell.execDetached(cmd);
    }

    function activate(i) {
        Panels.close();
        actions[i].run();
    }

    onOpenChanged: if (open) { current = 0; keys.forceActiveFocus(); }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.current = (root.current + 1) % root.actions.length;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                root.current = (root.current + root.actions.length - 1) % root.actions.length;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.activate(root.current);
            } else {
                const i = root.actions.findIndex(a => a.key === event.text.toUpperCase());
                if (i < 0) return;
                root.activate(i);
            }
            event.accepted = true;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 28
        opacity: root.fade

        Repeater {
            model: root.actions

            Column {
                id: item

                required property var modelData
                required property int index
                readonly property bool selected: root.current === index

                spacing: 14

                Item {
                    width: 112
                    height: 112

                    property real pop: 0
                    scale: pop
                    rotation: (1 - pop) * -120

                    Connections {
                        target: root
                        function onOpenChanged() { if (root.open) popIn.restart() }
                    }
                    SequentialAnimation {
                        id: popIn
                        ScriptAction { script: parent.pop = 0 }
                        PauseAnimation { duration: 60 + item.index * 55 }
                        SpatialAnim { target: parent; property: "pop"; from: 0; to: 1; speed: "fast" }
                    }

                    MaterialShape {
                        anchors.fill: parent
                        shape: item.selected ? item.modelData.shape : "circle"
                        color: item.selected ? Colors.m3primary : Colors.m3secondaryContainer
                        rotation: item.selected ? 30 : 0

                        Behavior on rotation { SpatialAnim { speed: "slow" } }
                    }

                    MIcon {
                        anchors.centerIn: parent
                        icon: item.modelData.icon
                        size: 40
                        fill: item.selected ? 1 : 0
                        color: item.selected ? Colors.m3onPrimary : Colors.m3onSecondaryContainer
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = item.index
                        onClicked: root.activate(item.index)
                    }
                }

                MText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    textStyle: item.selected ? Type.titleMediumEmph : Type.titleMedium
                    color: Colors.m3onSurface
                    text: item.modelData.label
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 28
                    height: 28
                    radius: 8
                    color: Colors.m3surfaceContainerHigh
                    opacity: item.selected ? 1 : 0.6

                    MText {
                        anchors.centerIn: parent
                        textStyle: Type.labelLargeEmph
                        color: Colors.m3onSurfaceVariant
                        text: item.modelData.key
                    }
                }
            }
        }
    }
}

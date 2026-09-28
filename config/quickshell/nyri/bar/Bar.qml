import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.widgets

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property ShellScreen modelData
        readonly property int gap: 12
        readonly property int islandHeight: 40
        readonly property int stripHeight: gap + islandHeight

        readonly property bool autohide: Config.o.bar.autohide
        readonly property bool emptyDesk: {
            const ws = Niri.workspaces.find(w => w.output === modelData.name && w.is_active);
            return !ws || Niri.windowCount(ws.id) === 0;
        }
        property bool pointerIn: false
        readonly property bool revealed: !autohide || pointerIn || Panels.current !== ""
                                         || Niri.overviewOpen || emptyDesk

        SpringValue {
            id: reveal
            target: bar.revealed ? 1 : 0
            damping: bar.revealed ? 0.62 : 1.0
            stiffness: bar.revealed ? 420 : 380
        }

        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: stripHeight + 16
        property bool settled: false
        Timer { running: true; interval: 600; onTriggered: bar.settled = true }
        exclusionMode: autohide && settled ? ExclusionMode.Ignore : ExclusionMode.Normal
        exclusiveZone: autohide ? 0 : stripHeight
        color: "transparent"

        IdleInhibitor {
            window: bar
            enabled: Toggles.caffeine
        }

        WlrLayershell.namespace: "nyri-bar"
        WlrLayershell.layer: autohide ? WlrLayer.Overlay : WlrLayer.Top

        mask: Region {
            Region { item: bar.autohide ? null : left }
            Region { item: bar.autohide ? null : center }
            Region { item: bar.autohide ? null : right }
            Region { item: bar.autohide ? (reveal.value > 0.5 ? strip : edge) : null }
        }

        Item { id: strip; width: bar.width; height: bar.stripHeight + 4 }
        Item { id: edge; width: bar.width; height: 3 }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    leave.stop();
                    bar.pointerIn = true;
                } else {
                    leave.restart();
                }
            }
        }

        Timer {
            id: leave
            interval: 450
            onTriggered: bar.pointerIn = false
        }

        Item {
            id: content
            width: bar.width
            height: bar.height
            transform: Translate { y: (1 - reveal.value) * -(bar.stripHeight + 12) }
            opacity: Math.min(1, reveal.value * 2)

            Row {
                id: left
                x: bar.gap
                y: bar.gap
                spacing: 8

                LauncherButton {}
                Workspaces { output: bar.modelData.name; introIndex: 1 }
                WindowTitle {
                    introIndex: 2
                    visible: Config.o.bar.title && opacity > 0
                    maxTextWidth: Math.max(80, center.x - left.x - 40 - 8 - 200 - 60)
                }
            }

            Clock {
                id: center
                introIndex: 3
                x: (bar.width - width) / 2
                y: bar.gap
            }

            Row {
                id: right
                x: bar.width - width - bar.gap
                y: bar.gap
                spacing: 8

                Tray { barWindow: bar; visible: Config.o.bar.tray && hasItems; introIndex: 4 }
                Status { introIndex: 5 }
                PanelButton {}
            }
        }
    }
}

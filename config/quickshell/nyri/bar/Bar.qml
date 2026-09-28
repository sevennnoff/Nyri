import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray as ST
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

        Rectangle {
            visible: Config.o.bar.style === "strip"
            width: bar.width
            height: bar.stripHeight + 4 - bar.gap / 2
            y: (1 - reveal.value) * -(bar.stripHeight + 12)
            color: Colors.m3surfaceContainer
            opacity: Math.min(1, reveal.value * 2)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Colors.m3outlineVariant; opacity: 0.6 }
        }

        readonly property var leftIds: Array.isArray(Config.o.bar.left) ? Config.o.bar.left : ["launcher", "workspaces", "title"]
        readonly property var centerIds: Array.isArray(Config.o.bar.center) ? Config.o.bar.center : ["clock", "live"]
        readonly property var rightIds: Array.isArray(Config.o.bar.right) ? Config.o.bar.right : ["tray", "status", "control"]

        readonly property var registry: ({
            launcher: launcherC, workspaces: workspacesC, title: titleC, clock: clockC, live: liveC,
            tray: trayC, status: statusC, control: controlC, weather: weatherC, media: mediaC
        })
        function wants(id) {
            if (id === "tray") return ST.SystemTray.items.values.length > 0;
            if (id === "weather") return Weather.ready;
            if (id === "media") return Media.player !== null;
            if (id === "title") return Niri.focusedWindow !== null;
            return true;
        }
        Component { id: launcherC; LauncherButton {} }
        Component { id: workspacesC; Workspaces { output: bar.modelData.name } }
        Component { id: titleC; WindowTitle { maxTextWidth: 360 } }
        Component { id: clockC; Clock {} }
        Component { id: liveC; LiveIsland {} }
        Component { id: trayC; Tray { barWindow: bar } }
        Component { id: statusC; Status {} }
        Component { id: controlC; PanelButton {} }
        Component { id: weatherC; WeatherIsland {} }
        Component { id: mediaC; MediaIsland {} }

        component Section: Row {
            id: sec
            property var ids: []
            property int base: 0
            spacing: 8
            Repeater {
                model: sec.ids
                Loader {
                    required property string modelData
                    required property int index
                    anchors.verticalCenter: parent?.verticalCenter
                    sourceComponent: bar.registry[modelData] ?? null
                    visible: bar.wants(modelData)
                    onLoaded: if (item.introIndex !== undefined) item.introIndex = sec.base + index
                }
            }
        }

        Item {
            id: content
            width: bar.width
            height: bar.height
            transform: Translate { y: (1 - reveal.value) * -(bar.stripHeight + 12) }
            opacity: Math.min(1, reveal.value * 2)

            Section {
                id: left
                x: bar.gap
                y: bar.gap
                ids: bar.leftIds
                base: 0
            }

            Section {
                id: center
                x: (bar.width - width) / 2
                y: bar.gap
                ids: bar.centerIds
                base: bar.leftIds.length
            }

            Section {
                id: right
                x: bar.width - width - bar.gap
                y: bar.gap
                ids: bar.rightIds
                base: bar.leftIds.length + bar.centerIds.length
            }
        }
    }
}

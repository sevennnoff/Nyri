import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

// Background layer. A new wallpaper opens as a circle from the centre over
// the old one. Parallax: the picture is a little larger than the screen and
// drifts on a slow spring when you change workspace (up/down) or scroll
// columns (sideways), and leans in when the overview opens. Between
// transitions nothing moves. niri puts this layer in the overview backdrop
// (layer-rule in config/niri/rules.kdl).
Variants {
    model: Quickshell.screens

    Scope {
    id: scope
    required property ShellScreen modelData

    PanelWindow {
        id: win

        readonly property ShellScreen modelData: scope.modelData

        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Colors.m3surface

        WlrLayershell.namespace: "nyri-wallpaper"
        WlrLayershell.layer: WlrLayer.Background

        // One picture across all screens (settings: "Единые обои"): the
        // picture covers the box around every monitor, and each screen shows
        // its own piece of it, placed where the monitor really is.
        readonly property bool span: Config.o.wallpaper.span && Quickshell.screens.length > 1
        readonly property rect box: {
            let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
            for (const s of Quickshell.screens) {
                x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y);
                x1 = Math.max(x1, s.x + s.width); y1 = Math.max(y1, s.y + s.height);
            }
            return Qt.rect(x0, y0, x1 - x0, y1 - y0);
        }

        readonly property size texture: Qt.size(stage.width * modelData.devicePixelRatio * 1.1, stage.height * modelData.devicePixelRatio * 1.1)

        // ── Parallax ──
        readonly property var myWorkspaces: Niri.workspacesOn(modelData.name)
        readonly property var activeWs: myWorkspaces.find(w => w.is_active) ?? null
        readonly property real wsPos: myWorkspaces.length > 1 && activeWs
            ? (myWorkspaces.indexOf(activeWs)) / (myWorkspaces.length - 1) : 0.5
        readonly property var columns: {
            if (!activeWs) return { at: 0, count: 1 };
            let count = 1, at = 1;
            for (const id in Niri.windows) {
                const w = Niri.windows[id];
                const c = w.workspace_id === activeWs.id ? w.layout?.pos_in_scrolling_layout?.[0] ?? 0 : 0;
                count = Math.max(count, c);
                if (w.is_focused && c) at = c;
            }
            return { at, count };
        }
        readonly property real colPos: columns.count > 1 ? (columns.at - 1) / (columns.count - 1) : 0.5
        readonly property real zoom: Niri.overviewOpen ? 1.12 : 1.08
        readonly property real slackX: width * (zoom - 1) / 2
        readonly property real slackY: height * (zoom - 1) / 2

        SpringValue { id: px; target: (0.5 - win.colPos) * 2 * win.slackX * 0.8; damping: 0.85; stiffness: 90; epsilon: 0.05 }
        SpringValue { id: py; target: (0.5 - win.wsPos) * 2 * win.slackY * 0.8; damping: 0.85; stiffness: 90; epsilon: 0.05 }
        SpringValue { id: pz; target: win.zoom; damping: 0.9; stiffness: 120; epsilon: 0.0005 }
        // Arrival after unlock: from the lock screen's framing (a touch
        // wider) the picture eases in to its usual zoom.
        Connections {
            target: Lock
            function onUnlocked() { pz.value = 1.0; pz.velocity = 0; pz.running = true; }
        }
        property string shown: ""
        property string incoming: ""

        Item {
            id: stage
            x: win.span ? win.box.x - win.modelData.x : 0
            y: win.span ? win.box.y - win.modelData.y : 0
            width: win.span ? win.box.width : win.width
            height: win.span ? win.box.height : win.height
            scale: pz.value
            transform: Translate { x: px.value; y: py.value }

        Image {
            id: base
            anchors.fill: parent
            source: win.shown ? "file://" + win.shown : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: win.texture
        }

        // The reveal: a circle that grows until it covers the screen.
        ClippingRectangle {
            id: reveal

            property real size: 0
            readonly property real diagonal: Math.hypot(win.width, win.height)

            // Centred on this screen, wherever it sits in the stage.
            x: -stage.x + (win.width - size) / 2
            y: -stage.y + (win.height - size) / 2
            width: size
            height: size
            radius: size / 2
            color: "transparent"
            visible: win.incoming !== ""

            Image {
                id: next
                x: -reveal.x
                y: -reveal.y
                width: stage.width
                height: stage.height
                source: win.incoming ? "file://" + win.incoming : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: win.texture
                onStatusChanged: if (status === Image.Ready) grow.restart()
            }

            NumberAnimation {
                id: grow
                target: reveal
                property: "size"
                from: 0
                to: reveal.diagonal
                duration: 900
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedDecel.curve
                onFinished: {
                    win.shown = win.incoming;
                    win.incoming = "";
                    reveal.size = 0;
                }
            }
        }

        }

        Connections {
            target: Colors
            function onWallpaperChanged() {
                if (!win.shown) win.shown = Colors.wallpaper;
                else if (Colors.wallpaper !== win.shown) win.incoming = Colors.wallpaper;
            }
        }

        Component.onCompleted: if (Colors.wallpaper) shown = Colors.wallpaper
    }

    // Widgets get their own surface on the bottom layer: the wallpaper sits
    // in niri's overview backdrop, which takes no clicks. Input only where
    // the widgets are. They stay put while the picture drifts under them.
    PanelWindow {
        screen: scope.modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: Config.o.desktop.enabled

        WlrLayershell.namespace: "nyri-desktop"
        WlrLayershell.layer: WlrLayer.Bottom

        mask: widgets.mask

        DesktopWidgets {
            id: widgets
            anchors.fill: parent
            bare: win.activeWs ? !Object.values(Niri.windows).some(w => w.workspace_id === win.activeWs.id) : true
        }
    }
    }
}

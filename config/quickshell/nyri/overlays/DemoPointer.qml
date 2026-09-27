import QtQuick
import QtQuick.Shapes as Vec
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.widgets

// The demo pointer: an arrow that glides to where the script points, and a
// ripple when it "clicks". Takes no input. Only exists in the test window.
PanelWindow {
    id: root

    visible: Demo.allowed && Demo.pointer
    screen: Panels.screen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "nyri-demo"
    WlrLayershell.layer: WlrLayer.Overlay

    // Brisk like a hand; glued to the widget while it is being dragged.
    SpringValue { id: px; target: Demo.x; damping: 0.9; stiffness: Demo.holding ? 4000 : 320; epsilon: 0.1 }
    SpringValue { id: py; target: Demo.y; damping: 0.9; stiffness: Demo.holding ? 4000 : 320; epsilon: 0.1 }

    // Click ripple.
    Rectangle {
        id: ripple
        property real t: 1
        x: px.value - width / 2
        y: py.value - height / 2
        width: 16 + 56 * t
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 3
        border.color: Colors.m3primary
        opacity: 1 - t
        NumberAnimation on t { id: rip; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic; running: false }
    }
    Connections { target: Demo; function onClicksChanged() { rip.restart(); press.value = 0.8; press.running = true; } }
    SpringValue { id: press; target: 1; damping: 0.5; stiffness: 600 }

    Vec.Shape {
        x: px.value - 3
        y: py.value - 2
        width: 26
        height: 34
        scale: press.value
        transformOrigin: Item.TopLeft
        preferredRendererType: Vec.Shape.CurveRenderer
        Vec.ShapePath {
            fillColor: "white"
            strokeColor: "#1a1a1a"
            strokeWidth: 2
            joinStyle: Vec.ShapePath.RoundJoin
            startX: 3; startY: 2
            PathLine { x: 3; y: 26 }
            PathLine { x: 9; y: 20 }
            PathLine { x: 13; y: 30 }
            PathLine { x: 17; y: 28 }
            PathLine { x: 13; y: 19 }
            PathLine { x: 21; y: 19 }
            PathLine { x: 3; y: 2 }
        }
    }
}

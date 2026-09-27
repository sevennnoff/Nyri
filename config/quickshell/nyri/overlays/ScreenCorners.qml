import QtQuick
import QtQuick.Shapes as Vec
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

// Rounded screen corners, as the old setup had: four tiny click-through
// surfaces on the overlay layer (so they round fullscreen apps too).
// Static vector shapes — drawn once, then nothing moves.
Variants {
    model: Config.o.bar.corners ? Quickshell.screens : []

    Scope {
        id: scope
        required property ShellScreen modelData

        Corner { top: true; left: true }
        Corner { top: true; right: true }
        Corner { bottom: true; left: true }
        Corner { bottom: true; right: true }

        component Corner: PanelWindow {
            id: corner

            property bool top: false
            property bool bottom: false
            property bool left: false
            property bool right: false
            readonly property int r: 18

            screen: scope.modelData
            anchors.top: top
            anchors.bottom: bottom
            anchors.left: left
            anchors.right: right
            implicitWidth: r
            implicitHeight: r
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}

            WlrLayershell.namespace: "nyri-corner"
            WlrLayershell.layer: WlrLayer.Overlay

            // Black everywhere outside a quarter circle centred inward.
            Vec.Shape {
                anchors.fill: parent
                preferredRendererType: Vec.Shape.CurveRenderer
                transform: Scale {
                    origin.x: corner.r / 2
                    origin.y: corner.r / 2
                    xScale: corner.right ? -1 : 1
                    yScale: corner.bottom ? -1 : 1
                }

                Vec.ShapePath {
                    fillColor: "black"
                    strokeColor: "transparent"
                    startX: 0
                    startY: 0
                    PathLine { x: corner.r; y: 0 }
                    PathArc { x: 0; y: corner.r; radiusX: corner.r; radiusY: corner.r; direction: PathArc.Counterclockwise }
                    PathLine { x: 0; y: 0 }
                }
            }
        }
    }
}

import QtQuick
import qs.theme

Item {
    id: root

    property real value: 0
    property bool wavy: true
    property bool flowing: wavy
    property color activeColor: Colors.m3primary
    property color trackColor: Colors.m3secondaryContainer
    property real amplitude: wavy ? 3 : 0
    readonly property real wavelength: 28
    readonly property real stroke: 4
    signal seek(real value)

    implicitHeight: 24

    Behavior on amplitude { SpatialAnim { speed: "fast" } }

    readonly property real pad: stroke / 2
    readonly property real mid: height / 2
    readonly property real split: pad + (width - 2 * pad) * Math.max(0, Math.min(1, value))
    readonly property real gap: 5 + stroke
    readonly property real waveEnd: split - gap

    Canvas {
        id: track
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pad = root.pad, mid = root.mid, split = root.split;
            ctx.lineCap = "round";
            ctx.lineWidth = root.stroke;

            ctx.strokeStyle = root.trackColor;
            if (split + root.gap < width - pad) {
                ctx.beginPath();
                ctx.moveTo(split + root.gap, mid);
                ctx.lineTo(width - pad, mid);
                ctx.stroke();

                ctx.fillStyle = root.activeColor;
                ctx.beginPath();
                ctx.arc(width - pad, mid, root.stroke / 2, 0, Math.PI * 2);
                ctx.fill();
            }

            ctx.strokeStyle = root.activeColor;
            ctx.beginPath();
            ctx.moveTo(split, mid - 9);
            ctx.lineTo(split, mid + 9);
            ctx.stroke();
        }
    }

    Item {
        id: clipBox
        x: root.pad
        width: Math.max(0, root.waveEnd - root.pad)
        height: parent.height
        clip: true
        visible: root.waveEnd > root.pad

        Canvas {
            id: wave
            width: clipBox.width + root.wavelength
            height: parent.height
            x: -root.wavelength

            NumberAnimation on x {
                id: flow
                running: root.flowing && root.amplitude > 0.05 && clipBox.visible
                from: -root.wavelength
                to: 0
                duration: 1100
                loops: Animation.Infinite
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const mid = root.mid, amp = root.amplitude, L = root.wavelength;
                ctx.lineCap = "round";
                ctx.lineWidth = root.stroke;
                ctx.strokeStyle = root.activeColor;
                ctx.beginPath();
                for (let x = 0; x <= width; x += 1) {
                    const y = mid + amp * Math.sin((x / L) * Math.PI * 2);
                    x === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                }
                ctx.stroke();
            }
        }
    }

    Rectangle {
        visible: clipBox.visible
        x: clipBox.x - width / 2
        y: root.mid + root.amplitude * Math.sin(-wave.x / root.wavelength * Math.PI * 2) - height / 2
        width: root.stroke
        height: root.stroke
        radius: root.stroke / 2
        color: root.activeColor
    }
    Rectangle {
        visible: clipBox.visible
        x: clipBox.x + clipBox.width - width / 2
        y: root.mid + root.amplitude * Math.sin((clipBox.width - wave.x) / root.wavelength * Math.PI * 2) - height / 2
        width: root.stroke
        height: root.stroke
        radius: root.stroke / 2
        color: root.activeColor
    }

    function repaintAll() { track.requestPaint(); wave.requestPaint(); }
    onSplitChanged: track.requestPaint()
    onAmplitudeChanged: wave.requestPaint()
    onActiveColorChanged: repaintAll()
    onTrackColorChanged: track.requestPaint()
    onWidthChanged: repaintAll()
    onHeightChanged: repaintAll()
    Connections { target: clipBox; function onWidthChanged() { wave.requestPaint() } }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.seek(Math.max(0, Math.min(1, m.x / root.width)))
    }
}

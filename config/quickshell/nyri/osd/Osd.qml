import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.widgets

// Drops out from under the clock. Never takes input, and unmaps when hidden.
PanelWindow {
    id: root

    readonly property real progress: spring.value

    SpringValue {
        id: spring
        target: Osd.shown ? 1 : 0
        damping: Osd.shown ? 0.6 : 1.0
        stiffness: Osd.shown ? 600 : 500
    }

    screen: Panels.screen
    visible: Osd.shown || progress > 0.001
    color: "transparent"
    anchors.top: true
    margins.top: 12 + 40 + 8
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: card.full + 32
    implicitHeight: card.height + 32
    mask: Region {}

    WlrLayershell.namespace: "nyri-osd"
    WlrLayershell.layer: WlrLayer.Overlay


    readonly property var spec: {
        switch (Osd.kind) {
        case "volume":
            return { icon: Audio.icon, value: Audio.muted ? 0 : Audio.volume, dim: Audio.muted };
        case "mic":
            return { icon: Audio.micMuted ? "mic_off" : "mic", text: Audio.micMuted ? "Микрофон выключен" : "Микрофон включён" };
        case "brightness":
            return { icon: Brightness.level < 0.35 ? "brightness_low" : Brightness.level < 0.7 ? "brightness_medium" : "brightness_high", value: Brightness.level };
        case "caps":
            return { icon: "keyboard_capslock", text: Toggles.capsLock ? "Caps Lock включён" : "Caps Lock выключен", dim: !Toggles.capsLock };
        case "layout":
            return { icon: "keyboard", text: Niri.layoutNames[Niri.layoutIndex] ?? "" };
        }
        return { icon: "info" };
    }

    // Opens from a circle into the full pill.
    Card {
        id: card
        readonly property real full: row.implicitWidth + 16
        y: 16 - (1 - root.progress) * 24
        width: 56 + (full - 56) * Math.max(0, root.progress)
        x: 16 + (full - width) / 2
        height: 56
        radius: height / 2
        color: Colors.m3surfaceContainerHigh
        elevation: 3
        opacity: Math.max(0, Math.min(1, root.progress * 3))
        clip: true

        Row {
            id: row
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: root.spec.dim ? Colors.m3surfaceContainerHighest : Colors.m3primaryContainer

                MIcon {
                    anchors.centerIn: parent
                    icon: root.spec.icon
                    fill: 1
                    color: root.spec.dim ? Colors.m3onSurfaceVariant : Colors.m3onPrimaryContainer
                }
            }

            MSlider {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.spec.value !== undefined
                width: 220
                interactive: false
                value: root.spec.value ?? 0
                activeColor: root.spec.dim ? Colors.m3outline : Colors.m3primary
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.spec.value !== undefined
                width: 40
                height: 24

                RollingText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    textStyle: Type.titleMediumEmph
                    text: String(Math.round((root.spec.value ?? 0) * 100))
                }
            }

            FlowText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.spec.text !== undefined
                rightPadding: 12
                textStyle: Type.titleMediumEmph
                text: root.spec.text ?? ""
            }
        }
    }
}

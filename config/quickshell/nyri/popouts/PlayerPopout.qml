import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Surface {
    id: root

    name: "player"
    keyboard: false

    readonly property var player: Media.player
    readonly property bool playing: player?.isPlaying ?? false
    property bool lyricsOn: true

    onOpenChanged: {
        if (open) Lyrics.wanted++;
        else Lyrics.wanted = Math.max(0, Lyrics.wanted - 1);
    }
    Timer {
        running: root.open && root.playing
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }
    function esc(t) { return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
    function karaoke(text, p) {
        const parts = text.split(/(\s+)/);
        const total = text.replace(/\s+/g, "").length || 1;
        let done = 0, lit = "", rest = "", on = true;
        for (const w of parts) {
            if (on && w.trim()) {
                done += w.length;
                if ((done - w.length) / total > p) on = false;
            }
            if (on) lit += w; else rest += w;
        }
        return "<font color='" + Colors.m3primary + "'>" + esc(lit) + "</font><font color='" + Colors.m3onSurfaceVariant + "'>" + esc(rest) + "</font>";
    }
    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    Popout {
        id: card
        progress: root.progress
        toW: root.lyricsOn && !Lyrics.none ? 760 : 420
        toX: Math.max(12, Math.min(parent.width - toW - 12, (Panels.anchorW > 0 ? Panels.anchorX + Panels.anchorW / 2 : parent.width / 2) - toW / 2))
        toH: 500
        Behavior on toW { SpatialAnim {} }

        Item {
            id: side
            x: 20
            y: 20
            width: 380
            height: parent.height - 40

            Item { id: coverSlot; width: 380; height: 230 }

            Column {
                y: coverSlot.height + 16
                width: parent.width
                spacing: 4

                FlowText {
                    width: parent.width
                    elide: Text.ElideRight
                    textStyle: ({ size: 22, weight: 650, rond: 50 })
                    text: root.player?.trackTitle || "Ничего не играет"
                }
                FlowText {
                    width: parent.width
                    elide: Text.ElideRight
                    textStyle: Type.bodyMedium
                    color: Colors.m3onSurfaceVariant
                    text: [root.player?.trackArtist, root.player?.identity].filter(Boolean).join(" · ")
                }

                Item {
                    width: parent.width
                    height: 28
                    visible: root.player?.lengthSupported ?? false
                    MText {
                        id: posT
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        textStyle: Type.labelMedium
                        font.features: { "tnum": 1 }
                        color: Colors.m3onSurfaceVariant
                        text: root.fmt(root.player?.position ?? 0)
                    }
                    WavyProgress {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 44
                        width: parent.width - 88
                        value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                        wavy: root.playing
                        flowing: root.open && root.playing
                        onSeek: v => { if (root.player?.canSeek) root.player.position = v * root.player.length }
                    }
                    MText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        textStyle: Type.labelMedium
                        font.features: { "tnum": 1 }
                        color: Colors.m3onSurfaceVariant
                        text: root.fmt(root.player?.length ?? 0)
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    topPadding: 4

                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "lyrics"
                        style: root.lyricsOn ? "tonal" : "standard"
                        onClicked: root.lyricsOn = !root.lyricsOn
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "skip_previous"; size: 52; iconSize: 30
                        enabled: root.player?.canGoPrevious ?? false
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.player.previous()
                    }
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 72; height: 72
                        scale: sq.value
                        SpringValue { id: sq; target: playL.pressed ? 0.86 : 1; damping: 0.45; stiffness: 900; epsilon: 0.001 }
                        MaterialShape {
                            anchors.fill: parent
                            shape: root.playing ? "square" : "cookie9Sided"
                            color: Colors.m3primary
                            rotation: root.playing ? 0 : spinS.value
                            SpringValue { id: spinS; target: root.playing ? 0 : 20; damping: 0.6; stiffness: 200 }
                        }
                        MIcon { anchors.centerIn: parent; icon: root.playing ? "pause" : "play_arrow"; size: 34; fill: 1; color: Colors.m3onPrimary }
                        StateLayer { id: playL; radius: width / 2; color: Colors.m3onPrimary; onClicked: root.player.togglePlaying() }
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "skip_next"; size: 52; iconSize: 30
                        enabled: root.player?.canGoNext ?? false
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.player.next()
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "queue_music"
                        onClicked: { Panels.close(); root.player?.raise(); }
                    }
                }
            }
        }

        Rectangle {
            id: lyricsBox
            x: side.x + side.width + 16
            y: 20
            width: card.toW - x - 20
            height: parent.height - 40
            radius: Shape.large
            color: Colors.m3surfaceContainerHigh
            visible: root.lyricsOn && !Lyrics.none && width > 40
            clip: true

            ListView {
                id: lyricList
                anchors.fill: parent
                anchors.margins: 12
                model: Lyrics.lines.length
                spacing: 6
                interactive: true
                Overscroll { flick: lyricList }
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: height * 0.35
                preferredHighlightEnd: height * 0.5
                highlightMoveDuration: 500
                currentIndex: Math.max(0, Lyrics.current)

                delegate: Item {
                    id: line
                    required property int index
                    readonly property var l: Lyrics.lines[index]
                    readonly property bool now: index === Lyrics.current
                    readonly property bool past: Lyrics.synced && index < Lyrics.current
                    width: lyricList.width
                    height: txt.implicitHeight + 8
                    SpringValue { id: lit; target: line.now ? 1 : 0; damping: 0.7; stiffness: 380 }

                    MText {
                        id: txt
                        width: parent.width - 16
                        x: 8 + 6 * lit.value
                        y: 4
                        wrapMode: Text.Wrap
                        font.pixelSize: 17 + 3 * lit.value
                        font.variableAxes: ({ "wght": 500 + 250 * lit.value })
                        color: line.now ? Colors.m3primary : Colors.m3onSurface
                        opacity: !Lyrics.synced ? 0.9 : line.now ? 1 : line.past ? 0.35 : 0.6
                        textFormat: line.now ? Text.StyledText : Text.PlainText
                        text: line.now && Lyrics.synced ? root.karaoke(line.l?.text || "♪", Lyrics.lineProgress) : (line.l?.text || "♪")
                        Behavior on opacity { EffectAnim {} }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: Lyrics.synced
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Lyrics.seek(line.index)
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: Lyrics.lines.length === 0
                spacing: 12
                LoadingIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56; height: 56
                    running: Lyrics.loading && lyricsBox.visible
                    visible: Lyrics.loading
                }
                MText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    textStyle: Type.bodyMedium
                    color: Colors.m3onSurfaceVariant
                    text: Lyrics.loading ? "Ищу текст…" : "Текста нет"
                }
            }
        }
    }

    ClippingRectangle {
        id: flyer
        readonly property real p: Math.max(0, Math.min(1.05, root.progress))
        readonly property real fromX: Panels.anchorW > 0 ? Panels.anchorX + 6 : card.toX + 20
        readonly property real fromY: 12 + 6
        readonly property real toX: card.x + side.x
        readonly property real toY: card.y + side.y
        x: fromX + (toX - fromX) * p
        y: fromY + (toY - fromY) * p
        width: 28 + (coverSlot.width - 28) * p
        height: 28 + (coverSlot.height - 28) * p
        radius: 14 + (Shape.large - 14) * Math.min(1, p)
        color: Colors.m3secondaryContainer
        opacity: Math.min(1, root.progress * 3)
        visible: root.visible

        Image {
            id: big
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(760, 480)
            asynchronous: true
        }
        MaterialShape {
            anchors.centerIn: parent
            visible: big.status !== Image.Ready
            width: Math.min(parent.width, parent.height) * 0.6
            height: width
            shape: "cookie12Sided"
            color: Colors.m3primaryContainer
            MIcon { anchors.centerIn: parent; icon: "music_note"; size: parent.width * 0.4; fill: 1; color: Colors.m3onPrimaryContainer }
        }
    }
}

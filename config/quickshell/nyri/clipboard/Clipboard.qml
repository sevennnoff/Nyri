import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.widgets

Surface {
    id: root

    name: "clipboard"

    property var entries: []
    readonly property string thumbs: Quickshell.env("XDG_RUNTIME_DIR") + "/nyri-clip"
    readonly property var shown: {
        const q = field.text.trim().toLowerCase();
        return q ? entries.filter(e => !e.image && e.text.toLowerCase().includes(q)) : entries;
    }

    function parse(out) {
        return out.split("\n").filter(Boolean).map(line => {
            const tab = line.indexOf("\t");
            const text = line.slice(tab + 1);
            const img = text.match(/^\[\[ binary data .* (png|jpe?g|webp|bmp|gif) (\d+x\d+) \]\]$/);
            return { line, id: line.slice(0, tab), text, image: !!img, size: img ? img[2] : "" };
        });
    }

    function copy(e) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "_", e.line]);
        Panels.close();
    }

    function forget(e) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "_", e.line]);
        entries = entries.filter(x => x.id !== e.id);
    }

    onOpenChanged: {
        if (open) {
            field.text = "";
            list.currentIndex = 0;
            load.running = true;
            field.input.forceActiveFocus();
        }
    }

    Process {
        id: load
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.entries = root.parse(text) }
    }

    Popout {
        progress: root.progress
        toX: (parent.width - toW) / 2
        toW: 640
        toH: col.implicitHeight + 24

        Behavior on toH { SpatialAnim {} }

        Column {
            id: col
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 8

            SearchField {
                id: field
                width: parent.width
                icon: "content_paste"
                placeholder: "Буфер обмена · Shift+Del удалить"

                input.Keys.onPressed: event => {
                    const e = root.shown[list.currentIndex];
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        list.incrementCurrentIndex();
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                        list.decrementCurrentIndex();
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && e) {
                        root.copy(e);
                    } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier) && e) {
                        root.forget(e);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }

            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, 480)
                model: root.shown
                clip: true
                spacing: 2
                Overscroll { flick: list; step: 0.6 }
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: false

                highlight: Rectangle {
                    width: list.width
                    height: list.currentItem?.height ?? 0
                    y: hl.value
                    radius: Shape.largeIncreased
                    color: Colors.m3secondaryContainer

                    SpringValue { id: hl; target: list.currentItem?.y ?? 0; damping: 0.72; stiffness: 700; epsilon: 0.1 }
                    Behavior on height { SpatialAnim { speed: "fast" } }
                }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property string thumb: root.thumbs + "/" + modelData.id + ".png"

                    width: list.width
                    height: modelData.image ? 112 : 52

                    Component.onCompleted: {
                        if (modelData.image)
                            Quickshell.execDetached(["sh", "-c",
                                "mkdir -p \"$2\"; f=\"$2/$3.png\"; [ -s \"$f\" ] || printf '%s' \"$1\" | cliphist decode > \"$f\"",
                                "_", modelData.line, root.thumbs, modelData.id]);
                    }

                    Image {
                        id: img
                        visible: row.modelData.image
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        height: 96
                        width: Math.min(sourceSize.width > 0 ? 96 * sourceSize.width / sourceSize.height : 96, 240)
                        source: row.modelData.image ? "file://" + row.thumb : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.height: 192
                        asynchronous: true
                        cache: false
                        onStatusChanged: if (status === Image.Error) retry.start()
                        Timer { id: retry; interval: 300; onTriggered: { img.source = ""; img.source = "file://" + row.thumb } }
                    }

                    MText {
                        anchors.verticalCenter: parent.verticalCenter
                        x: row.modelData.image ? img.x + img.width + 16 : 20
                        width: parent.width - x - 16
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        textStyle: Type.bodyLarge
                        color: row.current ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                        text: row.modelData.image ? "Изображение " + row.modelData.size.replace("x", "×") : row.modelData.text.replace(/\s+/g, " ")
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: root.copy(row.modelData)
                    }
                }
            }

            MText {
                visible: list.count === 0
                width: parent.width
                height: 56
                horizontalAlignment: Text.AlignHCenter
                textStyle: Type.bodyMedium
                color: Colors.m3onSurfaceVariant
                text: load.running ? "Загружаю…" : "Пусто"
            }
        }
    }
}

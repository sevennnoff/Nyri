import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

// The overflow of the bar's tray, grown out of its chevron.
Surface {
    id: root

    name: "tray"
    keyboard: false

    readonly property var items: SystemTray.items.values.slice(4)

    Popout {
        progress: root.progress
        toX: Math.max(12, Math.min(Panels.anchorX + Panels.anchorW / 2 - toW / 2, parent.width - toW - 12))
        toW: 4 * 72 + 32
        toH: grid.implicitHeight + 32

        Grid {
            id: grid
            x: 16
            y: 16
            columns: 4

            Repeater {
                model: root.items

                Item {
                    id: cell
                    required property var modelData
                    width: 72
                    height: 80

                    StateLayer {
                        radius: Shape.large
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => {
                            if (m.button === Qt.RightButton || cell.modelData.onlyMenu) {
                                const p = cell.mapToItem(null, m.x, m.y);
                                cell.modelData.display(root, p.x, p.y);
                            } else {
                                cell.modelData.activate();
                                Panels.close();
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 8
                        width: 44
                        height: 44
                        radius: 22
                        color: Colors.m3surfaceContainerHighest

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 24
                            source: cell.modelData.icon
                        }
                    }

                    MText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 58
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        textStyle: Type.labelSmall
                        color: Colors.m3onSurfaceVariant
                        text: cell.modelData.tooltipTitle || cell.modelData.title || cell.modelData.id
                    }
                }
            }
        }
    }
}

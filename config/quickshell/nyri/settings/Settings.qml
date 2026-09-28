import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

Scope {
    id: root

    readonly property bool open: Panels.settingsOpen

    readonly property var pages: [
        { id: "look",   icon: "palette",         label: "Оформление",     short: "Вид" },
        { id: "bar",    icon: "toolbar",         label: "Панель",         short: "Панель" },
        { id: "notif",  icon: "notifications",   label: "Уведомления",    short: "Увед." },
        { id: "power",  icon: "battery_full",    label: "Питание и сон",  short: "Питание" },
        { id: "usage",  icon: "hourglass_top",   label: "Экранное время", short: "Время" },
        { id: "about",  icon: "info",            label: "О системе",      short: "Система" }
    ]

    function toggle() {
        Panels.settingsOpen = !Panels.settingsOpen;
    }

    LazyLoader {
        active: root.open

        FloatingWindow {
            id: win

            title: "Nyri · Настройки"
            visible: true
            implicitWidth: 960
            implicitHeight: 680
            minimumSize: Qt.size(720, 480)
            color: Colors.m3surfaceContainerLow

            onVisibleChanged: if (!visible) Panels.settingsOpen = false

            Shortcut {
                sequence: "Escape"
                onActivated: Panels.settingsOpen = false
            }

            function step(n) {
                const i = root.pages.findIndex(p => p.id === Panels.settingsPage);
                Panels.settingsPage = root.pages[(i + n + root.pages.length) % root.pages.length].id;
            }
            Shortcut { sequence: "PgDown"; onActivated: flick.flick(0, -2600) }
            Shortcut { sequence: "PgUp"; onActivated: flick.flick(0, 2600) }
            Shortcut { sequence: "Home"; onActivated: flick.contentY = -flick.topMargin }
            Shortcut { sequence: "End"; onActivated: flick.contentY = Math.max(-flick.topMargin, flick.contentHeight - flick.height + flick.bottomMargin) }
            Shortcut { sequence: "Ctrl+Tab"; onActivated: win.step(1) }
            Shortcut { sequence: "Ctrl+Backtab"; onActivated: win.step(-1) }
            Repeater {
                model: root.pages.length
                Item {
                    required property int index
                    Shortcut { sequence: "Alt+" + (index + 1); onActivated: Panels.settingsPage = root.pages[index].id }
                }
            }

            readonly property bool compact: width < 860

            Item {
                id: nav
                width: win.compact ? 96 : 260
                height: parent.height

                MText {
                    visible: !win.compact
                    x: 28
                    y: 28
                    textStyle: Type.headlineSmall
                    font.variableAxes: ({ "wght": 600 })
                    text: "Настройки"
                }

                Rectangle {
                    id: indicator
                    readonly property int index: root.pages.findIndex(p => p.id === Panels.settingsPage)
                    x: win.compact ? (nav.width - 56) / 2 : 12
                    width: win.compact ? 56 : nav.width - 24
                    height: win.compact ? 32 : 56
                    radius: height / 2
                    color: Colors.m3secondaryContainer
                    y: pill.value

                    SpringValue {
                        id: pill
                        target: navList.y + indicator.index * (win.compact ? 72 : 60) + (win.compact ? 6 : 0)
                        damping: 0.62
                        stiffness: 520
                        epsilon: 0.1
                    }
                }

                Column {
                    id: navList
                    x: win.compact ? 0 : 12
                    y: win.compact ? 24 : 88
                    width: win.compact ? nav.width : nav.width - 24
                    spacing: 4

                    Repeater {
                        model: root.pages

                        Item {
                            id: navItem

                            required property var modelData
                            readonly property bool picked: Panels.settingsPage === modelData.id

                            width: navList.width
                            height: win.compact ? 68 : 56

                            StateLayer {
                                visible: !win.compact
                                onClicked: Panels.settingsPage = navItem.modelData.id
                            }

                            MouseArea {
                                visible: win.compact
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Panels.settingsPage = navItem.modelData.id
                            }

                            MIcon {
                                x: win.compact ? (parent.width - width) / 2 : 18
                                y: win.compact ? 10 : (parent.height - height) / 2
                                icon: navItem.modelData.icon
                                size: 24
                                fill: navItem.picked ? 1 : 0
                                color: navItem.picked ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                            }

                            MText {
                                x: win.compact ? (parent.width - width) / 2 : 56
                                y: win.compact ? 44 : (parent.height - height) / 2
                                width: win.compact ? parent.width - 4 : implicitWidth
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                textStyle: navItem.picked ? Type.labelLargeEmph : Type.labelLarge
                                font.pixelSize: win.compact ? 12 : 15
                                color: navItem.picked ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                                text: win.compact ? navItem.modelData.short : navItem.modelData.label
                            }
                        }
                    }
                }
            }

            ClippingRectangle {
                id: pageBox
                x: nav.width
                y: 12
                width: parent.width - nav.width - 12
                height: parent.height - 24
                radius: Shape.extraLarge
                color: Colors.m3surface

                readonly property real headH: 64
                readonly property real largeH: 104
                readonly property real collapse: Math.max(0, Math.min(1, (flick.contentY + flick.topMargin) / (largeH - headH)))

                Flickable {
                    id: flick
                    anchors.fill: parent
                    topMargin: pageBox.largeH
                    bottomMargin: 28
                    contentHeight: pageLoader.item?.implicitHeight ?? 0
                    Overscroll { flick: flick }

                    Loader {
                        id: pageLoader
                        x: 28
                        width: flick.width - 56
                        source: "Page" + Panels.settingsPage.charAt(0).toUpperCase() + Panels.settingsPage.slice(1) + ".qml"
                        onSourceChanged: flick.contentY = -flick.topMargin

                        property real enter: 1
                        opacity: Math.min(1, enter * 1.4)
                        y: (1 - enter) * 40
                        onLoaded: { enter = 0; rise.restart(); }
                        SpatialAnim { id: rise; target: pageLoader; property: "enter"; from: 0; to: 1; speed: "default" }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: pageBox.headH
                    color: Colors.m3surfaceContainer
                    opacity: pageBox.collapse
                }

                FlowText {
                    x: 28
                    y: 40 + (18 - 40) * pageBox.collapse
                    textStyle: ({ size: 32, weight: 550, rond: 100 })
                    scale: 1 - (1 - 22 / 32) * pageBox.collapse
                    transformOrigin: Item.TopLeft
                    text: root.pages.find(p => p.id === Panels.settingsPage)?.label ?? ""
                }
            }
        }
    }
}

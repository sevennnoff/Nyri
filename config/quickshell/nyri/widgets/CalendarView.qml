import QtQuick
import qs.theme
import qs.widgets

Column {
    id: view

    property date today: new Date()
    property date shownMonth: new Date()

    function shift(n) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + n, 1);
    }

    readonly property var cells: {
        const first = new Date(shownMonth.getFullYear(), shownMonth.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(first.getFullYear(), first.getMonth(), 1 - offset + i));
        return out;
    }

    spacing: 8

    Item {
        width: parent.width
        height: 40

        MText {
            anchors.verticalCenter: parent.verticalCenter
            x: 4
            textStyle: Type.titleMediumEmph
            text: {
                const s = Qt.locale().standaloneMonthName(view.shownMonth.getMonth());
                return s.charAt(0).toUpperCase() + s.slice(1) + " " + view.shownMonth.getFullYear();
            }
        }

        Row {
            anchors.right: parent.right
            spacing: 4

            IconButton { icon: "chevron_left"; onClicked: view.shift(-1) }
            IconButton { icon: "today"; visible: view.shownMonth.getMonth() !== view.today.getMonth() || view.shownMonth.getFullYear() !== view.today.getFullYear(); onClicked: view.shownMonth = new Date() }
            IconButton { icon: "chevron_right"; onClicked: view.shift(1) }
        }
    }

    Grid {
        columns: 7
        width: parent.width

        Repeater {
            model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

            MText {
                required property string modelData
                required property int index
                width: view.width / 7
                height: 28
                horizontalAlignment: Text.AlignHCenter
                textStyle: Type.labelMedium
                color: index >= 5 ? Colors.m3primary : Colors.m3onSurfaceVariant
                text: modelData
            }
        }

        Repeater {
            model: view.cells

            Item {
                id: day

                required property var modelData
                readonly property bool inMonth: modelData.getMonth() === view.shownMonth.getMonth()
                readonly property bool isToday: modelData.toDateString() === view.today.toDateString()

                width: view.width / 7
                height: 44

                MaterialShape {
                    anchors.centerIn: parent
                    width: 42
                    height: 42
                    visible: day.isToday
                    shape: "cookie9Sided"
                    color: Colors.m3primary
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    radius: 20
                    color: Colors.m3onSurface
                    opacity: hover.hovered && !day.isToday ? 0.08 : 0

                    Behavior on opacity { EffectAnim {} }
                }

                HoverHandler { id: hover }

                MText {
                    anchors.centerIn: parent
                    textStyle: day.isToday ? Type.labelLargeEmph : Type.bodyMedium
                    color: day.isToday ? Colors.m3onPrimary : Colors.m3onSurface
                    opacity: day.inMonth ? 1 : 0.35
                    text: day.modelData.getDate()
                }
            }
        }
    }
}

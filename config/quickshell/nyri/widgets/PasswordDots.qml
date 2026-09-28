import QtQuick
import qs.theme

Row {
    id: root

    property int length: 0
    property int max: 14
    property real size: 16
    property color color: Colors.m3primary

    readonly property var pool: ["cookie4Sided", "clover4Leaf", "sunny", "pentagon", "gem",
                                 "puffy", "flower", "heart", "burst", "diamond", "pill", "arch"]

    spacing: 6

    onLengthChanged: sync()
    Component.onCompleted: sync()

    function sync() {
        while (chars.count < length)
            chars.append({ shape: pool[Math.floor(Math.random() * pool.length)] });
        while (chars.count > length)
            chars.remove(chars.count - 1);
    }

    ListModel { id: chars }

    Repeater {
        model: chars

        Item {
            id: slot
            required property int index
            required property string shape
            readonly property bool shown: index >= chars.count - root.max

            width: shown ? root.size : 0
            height: root.size
            visible: shown

            property bool born: false
            Component.onCompleted: Qt.callLater(() => slot.born = true)
            SpringValue { id: pop; target: slot.born ? 1 : 0; damping: 0.5; stiffness: 700 }

            MaterialShape {
                anchors.fill: parent
                shape: slot.shape
                color: root.color
                scale: Math.max(0, pop.value)
                rotation: (1 - pop.value) * -90
            }
        }
    }
}

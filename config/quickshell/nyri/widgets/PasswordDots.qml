import QtQuick
import qs.theme

// Password characters as small M3 shapes, one random shape per character.
// The model only ever grows or shrinks at the end, so typing adds one shape
// that springs in and backspace pops one out — the others never rebuild,
// which is what made them flicker when the model was a plain number.
Row {
    id: root

    property int length: 0
    property int max: 14                 // beyond this only the newest show
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

            // Arrival: from nothing, a quarter turn, settle with a bounce.
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

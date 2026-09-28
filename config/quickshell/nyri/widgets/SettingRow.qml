import QtQuick
import qs.theme

Rectangle {
    id: root

    readonly property bool isRow: true
    property bool first: false
    property bool last: false
    property string icon: ""
    property string title
    property string subtitle: ""
    property bool clickable: false
    default property alias trailing: slot.data
    property alias below: extra.data
    signal clicked

    readonly property real outer: Shape.largeIncreased
    readonly property real inner: Shape.extraSmall

    width: parent?.width ?? 0
    height: Math.max(72, head.height + 24) + (extra.children.length ? extra.implicitHeight + 12 : 0)
    color: Colors.m3surfaceContainer
    topLeftRadius: first ? outer : inner
    topRightRadius: first ? outer : inner
    bottomLeftRadius: last ? outer : inner
    bottomRightRadius: last ? outer : inner

    onVisibleChanged: parent?.restyle?.()

    property real dim: enabled ? 1 : 0.45
    Behavior on dim { EffectAnim {} }

    property bool born: false
    Timer {
        running: true
        interval: 16 + Math.min(10, Math.max(0, root.parent ? Array.prototype.indexOf.call(root.parent.children, root) : 0)) * 30
        onTriggered: root.born = true
    }
    SpringValue { id: arrive; target: root.born ? 1 : 0; damping: 0.72; stiffness: 360 }
    opacity: dim * Math.max(0, Math.min(1, arrive.value * 1.3))
    transform: Translate { y: (1 - arrive.value) * 28 }

    readonly property var switchItem: {
        for (let i = 0; i < slot.children.length; i++) {
            const c = slot.children[i];
            if (c.checked !== undefined && c.toggled !== undefined) return c;
        }
        return null;
    }

    StateLayer {
        visible: root.clickable || root.switchItem !== null
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        onClicked: root.switchItem ? root.switchItem.toggled(!root.switchItem.checked) : root.clicked()
    }

    Item {
        id: head
        x: 16
        y: 12
        width: parent.width - 32
        height: Math.max(48, texts.implicitHeight)

        MIcon {
            id: ico
            y: texts.height > titleText.height * 2.4 ? texts.y + (titleText.height - height) / 2
                                                      : (parent.height - height) / 2
            visible: root.icon !== ""
            icon: root.icon
            size: 24
            color: Colors.m3onSurfaceVariant
        }

        Column {
            id: texts
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: ico.visible ? ico.right : parent.left
            anchors.leftMargin: ico.visible ? 16 : 0
            anchors.right: slot.left
            anchors.rightMargin: 12

            MText {
                id: titleText
                width: parent.width
                elide: Text.ElideRight
                textStyle: Type.bodyLarge
                text: root.title
            }

            MText {
                width: parent.width
                visible: text !== ""
                wrapMode: Text.Wrap
                textStyle: Type.bodyMedium
                color: Colors.m3onSurfaceVariant
                text: root.subtitle
            }
        }

        Row {
            id: slot
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            onChildrenChanged: { for (const c of children) c.anchors.verticalCenter = slot.verticalCenter; }
        }
    }

    Column {
        id: extra
        x: root.icon !== "" ? 16 + 24 + 16 : 16
        y: head.y + head.height + 4
        width: parent.width - x - 16
    }
}

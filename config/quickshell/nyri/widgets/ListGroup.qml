import QtQuick
import qs.theme

Column {
    id: root

    property string title: ""
    default property alias rows: body.data

    spacing: 8

    MText {
        visible: root.title !== ""
        leftPadding: 16
        textStyle: Type.labelLargeEmph
        color: Colors.m3primary
        text: root.title
    }

    Column {
        id: body
        width: root.width
        spacing: 2

        function restyle() {
            const vis = [];
            for (let i = 0; i < children.length; i++)
                if (children[i].visible && children[i].isRow) vis.push(children[i]);
            vis.forEach((c, i) => {
                const prev = vis[i - 1], next = vis[i + 1];
                c.first = !prev || prev.choosing || c.choosing;
                c.last = !next || next.choosing || c.choosing;
            });
        }
        onChildrenChanged: Qt.callLater(restyle)
        Component.onCompleted: Qt.callLater(restyle)
    }
}

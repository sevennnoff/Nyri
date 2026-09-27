import QtQuick
import qs.theme

// Android 16-style grouped list: rows share a column with 2dp gaps; the group
// has large outer corners and small inner ones. Rows are SettingRow items.
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

        // Round the outer corners of the first and last visible rows.
        function restyle() {
            const vis = [];
            for (let i = 0; i < children.length; i++)
                if (children[i].visible && children[i].isRow) vis.push(children[i]);
            vis.forEach((c, i) => { c.first = i === 0; c.last = i === vis.length - 1; });
        }
        onChildrenChanged: Qt.callLater(restyle)
        Component.onCompleted: Qt.callLater(restyle)
    }
}

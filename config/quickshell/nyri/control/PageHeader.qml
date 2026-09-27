import QtQuick
import qs.theme
import qs.widgets

// Header of a control-center sub-page: back, title, optional master switch.
Item {
    id: root

    property string title
    property bool hasSwitch: false
    property bool checked: false
    signal back
    signal toggled(bool checked)

    width: parent?.width ?? 0
    height: 48

    IconButton {
        id: backBtn
        anchors.verticalCenter: parent.verticalCenter
        icon: "arrow_back"
        onClicked: root.back()
    }

    MText {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: backBtn.right
        anchors.leftMargin: 8
        textStyle: Type.titleLarge
        text: root.title
    }

    MSwitch {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        visible: root.hasSwitch
        checked: root.checked
        onToggled: c => root.toggled(c)
    }
}

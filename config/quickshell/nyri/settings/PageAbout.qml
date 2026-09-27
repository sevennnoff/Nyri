import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.widgets

Column {
    id: page

    spacing: 24
    property var info: ({})

    Process {
        running: true
        command: ["sh", "-c", "printf '%s\\n' \"$(niri --version)\" \"$(qs --version | head -1)\" \"$(uname -r)\" \"$(. /etc/os-release; echo $PRETTY_NAME)\" \"$(cat /sys/class/dmi/id/product_version 2>/dev/null || cat /sys/class/dmi/id/product_name)\" \"$(git -C $HOME/nyri log -1 --format='%h · %cr' 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                page.info = { niri: l[0], qs: l[1], kernel: l[2], os: l[3], host: l[4], nyri: l[5] };
            }
        }
    }

    Row {
        spacing: 20

        MaterialShape {
            width: 88
            height: 88
            shape: "cookie12Sided"
            color: Colors.m3primaryContainer

            MIcon {
                anchors.centerIn: parent
                icon: "laptop_chromebook"
                size: 40
                fill: 1
                color: Colors.m3onPrimaryContainer
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            MText {
                textStyle: Type.headlineMedium
                text: page.info.host ?? ""
            }

            MText {
                textStyle: Type.bodyMedium
                color: Colors.m3onSurfaceVariant
                text: page.info.os ?? ""
            }
        }
    }

    ListGroup {
        width: parent.width
        title: "Система"

        SettingRow { icon: "grid_view"; title: "niri"; subtitle: page.info.niri ?? "" }
        SettingRow { icon: "widgets"; title: "Quickshell"; subtitle: page.info.qs ?? "" }
        SettingRow { icon: "memory"; title: "Ядро"; subtitle: page.info.kernel ?? "" }
        SettingRow { icon: "commit"; title: "nyri"; subtitle: page.info.nyri ?? "" }
    }

    ListGroup {
        width: parent.width
        title: "Полезное"

        SettingRow {
            icon: "keyboard"
            title: "Горячие клавиши"
            clickable: true
            onClicked: Quickshell.execDetached(["niri", "msg", "action", "show-hotkey-overlay"])
        }

        SettingRow {
            icon: "folder_open"
            title: "Открыть папку Nyri"
            clickable: true
            onClicked: Quickshell.execDetached(["nemo", Quickshell.env("HOME") + "/nyri"])
        }
    }
}

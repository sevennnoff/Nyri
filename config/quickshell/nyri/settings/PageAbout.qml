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
        title: "Погода"

        SettingRow {
            id: cityRow
            icon: "location_on"
            title: "Город"
            subtitle: Config.o.weather.city + " · " + Config.o.weather.lat.toFixed(2) + ", " + Config.o.weather.lon.toFixed(2)

            below: Row {
                width: parent.width
                spacing: 8

                SearchField {
                    id: city
                    width: parent.width - 56
                    icon: "search"
                    placeholder: "Найти город"
                    input.onAccepted: find.clicked()
                }

                IconButton {
                    id: find
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "arrow_forward"
                    style: "filled"
                    size: 48
                    onClicked: if (city.text.trim()) geo.lookup(city.text.trim())
                }
            }

            Process {
                id: geo
                function lookup(name) {
                    command = ["curl", "-s", "--max-time", "10", "https://geocoding-api.open-meteo.com/v1/search?count=1&language=ru&name=" + encodeURIComponent(name)];
                    running = true;
                }
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const r = JSON.parse(text).results?.[0];
                            if (!r) { cityRow.subtitle = "Не нашёл такой город"; return; }
                            Config.o.weather.city = r.name;
                            Config.o.weather.lat = r.latitude;
                            Config.o.weather.lon = r.longitude;
                            city.text = "";
                            Weather.refresh();
                        } catch (e) {}
                    }
                }
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
            onClicked: Quickshell.execDetached(["nemo", Paths.root])
        }
    }
}

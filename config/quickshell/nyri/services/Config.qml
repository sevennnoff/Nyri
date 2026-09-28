pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias o: adapter

    FileView {
        path: Paths.state + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: adapter

            property JsonObject bar: JsonObject {
                property bool autohide: false
                property bool corners: true
                property bool title: true
                property bool tray: true
                property bool layout: true
                property bool date: true
                property var left: ["launcher", "workspaces", "title"]
                property var center: ["clock", "live"]
                property var right: ["tray", "status", "control"]
                property string style: "islands"
                property bool seconds: false
                property string workspaces: "pills"
                property bool volume: true
                property bool percent: true
                property bool mediaTitle: true
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7
            }

            property JsonObject idle: JsonObject {
                property int screenOff: 5
                property int lockAc: 10
                property int lockBattery: 15
                property int suspendBattery: 20
                property bool lockOnLogin: true
            }

            property JsonObject weather: JsonObject {
                property string city: "Белград"
                property real lat: 44.8176
                property real lon: 20.4633
            }

            property JsonObject night: JsonObject {
                property string mode: "off"
                property int temp: 3600
            }

            property JsonObject motion: JsonObject {
                property real speed: 1.0
            }

            property JsonObject wallpaper: JsonObject {
                property bool span: false
                property real scale: 1.0
            }

            property JsonObject theme: JsonObject {
                property string schedule: "off"
                property string darkAt: "21:00"
                property string lightAt: "07:00"
                property bool walls: true
            }

            property JsonObject desktop: JsonObject {
                property bool enabled: true
                property bool grid: true
                property int gridSize: 24
                property var positions: ({})
                property var variants: ({})
                property var scales: ({})
                property var only: ({})
                property bool clock: true
                property bool glance: true
                property bool battery: true
                property bool media: true
                property bool forecast: true
                property bool calendar: true
                property bool system: false
                property bool usage: false
            }

            property JsonObject screenTime: JsonObject {
                property bool enabled: true
            }

            property JsonObject privacy: JsonObject {
                property bool mode: false
                property bool autoOnCast: true
                property bool dndWhenActive: true
            }
        }
    }
}

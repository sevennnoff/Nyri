pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings, edited in the settings window and read everywhere else.
// Lives in Paths.state/settings.json (not the repo, so toggling a
// switch never dirties git). Writes itself on change; reloads when the file
// changes on disk.
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
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7          // seconds, normal urgency
            }

            // Minutes; 0 means never.
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
                property string mode: "off"      // off | on | auto (sunset to sunrise)
                property int temp: 3600
            }

            property JsonObject motion: JsonObject {
                property real speed: 1.0         // 0.6 slower … 1.6 faster
            }

            property JsonObject wallpaper: JsonObject {
                property bool span: false        // one picture across all monitors
            }

            // Widgets on the wallpaper.
            property JsonObject desktop: JsonObject {
                property bool enabled: true
                property bool grid: true         // snap to a grid when dropped
                property int gridSize: 24
                property var positions: ({})     // key -> { x, y }, set by dragging
                property var variants: ({})      // key -> which look, cycled by right click
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
        }
    }
}

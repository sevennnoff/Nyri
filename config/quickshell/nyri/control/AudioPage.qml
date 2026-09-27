import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

// Where sound goes, where it comes from, and how loud each app is.
Column {
    id: root

    signal back
    spacing: 16

    PwObjectTracker { objects: [...Audio.sinks, ...Audio.sources, ...Audio.streams] }

    PageHeader {
        title: "Звук"
        onBack: root.back()
    }

    component DeviceGroup: ListGroup {
        id: group
        property var nodes: []
        property var current: null
        width: root.width

        Repeater {
            model: ScriptModel { values: group.nodes }

            SettingRow {
                id: devRow
                required property var modelData
                color: Colors.m3surfaceContainerHigh
                icon: Audio.deviceIcon(modelData)
                title: Audio.label(modelData)
                clickable: true
                onClicked: Audio.setDefault(modelData)

                MRadio { checked: group.current === devRow.modelData }
            }
        }
    }

    DeviceGroup {
        title: "Выход"
        nodes: Audio.sinks
        current: Audio.sink
    }

    DeviceGroup {
        title: "Вход"
        nodes: Audio.sources
        current: Audio.source
        visible: Audio.sources.length > 0
    }

    ListGroup {
        width: root.width
        title: "Приложения"
        visible: Audio.streams.length > 0

        Repeater {
            model: ScriptModel { values: Audio.streams }

            SettingRow {
                id: stream
                required property var modelData
                readonly property string app: modelData.properties["application.name"] ?? Audio.label(modelData)
                color: Colors.m3surfaceContainerHigh
                icon: modelData.audio.muted ? "volume_off" : "volume_up"
                title: stream.app
                subtitle: modelData.properties["media.name"] ?? ""

                IconButton {
                    icon: stream.modelData.audio.muted ? "volume_off" : "volume_up"
                    size: 36
                    iconSize: 20
                    onClicked: stream.modelData.audio.muted = !stream.modelData.audio.muted
                }

                below: MSlider {
                    width: parent.width
                    value: stream.modelData.audio.volume
                    onMoved: v => stream.modelData.audio.volume = v
                }
            }
        }
    }
}

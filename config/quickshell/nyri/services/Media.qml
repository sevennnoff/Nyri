pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    readonly property var players: Mpris.players.values
    property var chosen: null
    readonly property var player: (chosen && players.indexOf(chosen) >= 0 ? chosen : null) ?? players.find(p => p.isPlaying) ?? players[0] ?? null
}

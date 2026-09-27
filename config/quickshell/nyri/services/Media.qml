pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    readonly property var players: Mpris.players.values
    // The playing one wins; otherwise whatever was there first.
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
}

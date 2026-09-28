pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string family: "Rubik"
    readonly property string iconFamily: "Material Symbols Rounded"
    readonly property string monoFamily: "JetBrainsMono Nerd Font"

    readonly property var displayLarge: ({ size: 57, weight: 450, rond: 100 })
    readonly property var displayLargeEmph: ({ size: 57, weight: 700, rond: 100 })
    readonly property var displaySmall: ({ size: 36, weight: 450, rond: 100 })
    readonly property var headlineSmall: ({ size: 24, weight: 450, rond: 100 })
    readonly property var headlineMedium: ({ size: 28, weight: 450, rond: 100 })
    readonly property var titleLarge: ({ size: 22, weight: 500, rond: 50 })
    readonly property var titleMedium: ({ size: 16, weight: 540, rond: 50 })
    readonly property var titleMediumEmph: ({ size: 16, weight: 700, rond: 100 })
    readonly property var titleSmall: ({ size: 14, weight: 540, rond: 50 })
    readonly property var bodyLarge: ({ size: 16, weight: 450, rond: 0 })
    readonly property var bodyMedium: ({ size: 14, weight: 450, rond: 0 })
    readonly property var bodySmall: ({ size: 12, weight: 450, rond: 0 })
    readonly property var labelLarge: ({ size: 14, weight: 540, rond: 50 })
    readonly property var labelLargeEmph: ({ size: 14, weight: 700, rond: 100 })
    readonly property var labelMedium: ({ size: 12, weight: 480, rond: 50 })
    readonly property var labelSmall: ({ size: 11, weight: 540, rond: 50 })
}

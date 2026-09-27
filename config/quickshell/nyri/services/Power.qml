pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    readonly property int profile: PowerProfiles.profile
    readonly property string label: profile === PowerProfile.PowerSaver ? "Экономия"
        : profile === PowerProfile.Performance ? "Производительность" : "Баланс"
    readonly property string icon: profile === PowerProfile.PowerSaver ? "eco"
        : profile === PowerProfile.Performance ? "bolt" : "balance"

    function cycle() {
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile)
            order.push(PowerProfile.Performance);
        PowerProfiles.profile = order[(order.indexOf(profile) + 1) % order.length];
    }
}

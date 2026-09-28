pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length
    property var arrived: ({})
    readonly property ListModel popups: ListModel {}

    function find(id) {
        return list.find(n => n.id === id) ?? null;
    }

    function timeoutFor(n) {
        if (!n || n.urgency === NotificationUrgency.Critical)
            return 0;
        if (n.expireTimeout > 0)
            return Math.min(n.expireTimeout, 30000);
        const normal = Config.o.notifications.timeout * 1000;
        return n.urgency === NotificationUrgency.Low ? Math.min(5000, normal) : normal;
    }

    function hidePopup(id) {
        for (let i = 0; i < popups.count; i++)
            if (popups.get(i).nid === id) {
                popups.remove(i);
                return;
            }
    }

    function invoke(n, action) {
        action.invoke();
        if (!n.resident)
            n.dismiss();
    }

    function clearAll() {
        for (const n of list.slice())
            n.dismiss();
    }

    function screenshotToast() {
        Quickshell.execDetached(["sh", "-c",
            "f=$(ls -t \"$HOME/Pictures/Screenshots\"/*.png 2>/dev/null | head -n1); [ -n \"$f\" ] || exit 0; " +
            "a=$(notify-send -a 'Скриншот' -i \"$f\" -h string:image-path:\"$f\" -A open=Открыть -A folder=Папка " +
            "'Скриншот сохранён' 'И скопирован в буфер обмена'); " +
            "case \"$a\" in open) xdg-open \"$f\";; folder) xdg-open \"${f%/*}\";; esac"]);
    }

    function ago(id) {
        const t = arrived[id];
        if (!t) return "";
        const min = Math.floor((Date.now() - t) / 60000);
        if (min < 1) return "сейчас";
        if (min < 60) return min + " мин";
        return Qt.formatTime(t, "HH:mm");
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            if (n.appName === "niri" && /screenshot/i.test(n.summary)) {
                n.dismiss();
                root.screenshotToast();
                return;
            }
            n.tracked = true;
            const a = Object.assign({}, root.arrived);
            a[n.id] = new Date();
            root.arrived = a;
            const quiet = root.dnd || (Privacy.active && Config.o.privacy.dndWhenActive);
            if (!n.lastGeneration && (!quiet || n.urgency === NotificationUrgency.Critical)) {
                root.hidePopup(n.id);
                root.popups.insert(0, { nid: n.id });
            }
            n.closed.connect(() => root.hidePopup(n.id));
        }
    }
}

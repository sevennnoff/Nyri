pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool daemon: false
    property var devices: []
    readonly property var paired: devices.filter(d => d.paired)
    readonly property var phone: paired.find(d => d.reachable) ?? paired[0] ?? null
    readonly property bool reachable: phone?.reachable ?? false
    readonly property var battery: phone?.battery ?? null
    readonly property var requests: devices.filter(d => d.pairRequested && !d.paired)

    function send(cmd) { if (proc.running) proc.write(cmd + "\n"); }
    function share(path) { if (phone) send("share " + phone.id + " " + path); }
    function shareText(t) { if (phone) send("text " + phone.id + " " + t.replace(/\n/g, " ")); }
    function sendClipboard() { if (phone) send("clip " + phone.id); }
    function ring() { if (phone) send("ring " + phone.id); }
    function ping() { if (phone) send("ping " + phone.id); }
    function browse() { if (phone) send("browse " + phone.id); }
    function pair(id) { send("pair " + id); }
    function accept(id) { send("accept " + id); }
    function unpair(id) { send("unpair " + id); }
    function openApp() { send("app"); }

    Process {
        id: proc
        running: !Panels.nested
        stdinEnabled: true
        command: [Paths.bin + "/nyri-phone"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const s = JSON.parse(line);
                    root.daemon = s.daemon;
                    root.devices = s.devices;
                } catch (e) {}
            }
        }
    }

    Timer {
        running: Demo.allowed
        interval: 1500
        onTriggered: if (!root.daemon) {
            root.daemon = true;
            root.devices = [{ id: "demo", name: "Телефон", type: "phone", reachable: true, paired: true, pairRequested: false,
                              battery: { charge: 68, charging: false }, signal: { type: "5G", strength: 3 } }];
        }
    }
}

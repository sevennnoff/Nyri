import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.theme
import qs.services
import qs.widgets

Scope {
    id: root

    PolkitAgent { id: agent }

    property bool demo: false
    QtObject {
        id: fake
        property string message: "Для установки пакетов нужен пароль администратора"
        property string actionId: "org.freedesktop.packagekit.package-install"
        property string iconName: ""
        property var identities: []
        property bool isResponseRequired: true
        property string inputPrompt: "Пароль:"
        property bool responseVisible: false
        property string supplementaryMessage: ""
        property bool supplementaryIsError: false
        function submit(v) { fakeCheck.restart(); }
        function cancelAuthenticationRequest() { root.demo = false; }
    }
    Timer {
        id: fakeCheck
        interval: 700
        onTriggered: { fake.supplementaryMessage = "Неверный пароль, попробуйте ещё раз"; fake.supplementaryIsError = true; root.failedAt = Date.now(); }
    }
    function showDemo() {
        fake.supplementaryMessage = "";
        fake.supplementaryIsError = false;
        demo = true;
    }

    readonly property var flow: agent.flow ?? (demo ? fake : null)
    readonly property bool open: flow !== null
    property string buffer: ""
    property bool waiting: false
    property real failedAt: 0
    property var shapes: []
    readonly property var shapePool: ["cookie4Sided", "clover4Leaf", "sunny", "pentagon", "gem", "puffy", "flower", "heart", "burst", "diamond"]

    function type(text) {
        buffer = text;
        const s = shapes.slice(0, text.length);
        while (s.length < text.length) s.push(shapePool[Math.floor(Math.random() * shapePool.length)]);
        shapes = s;
    }
    function submit() {
        if (!flow || waiting) return;
        waiting = true;
        flow.submit(buffer);
    }
    function cancel() {
        if (flow) flow.cancelAuthenticationRequest();
    }

    onOpenChanged: { type(""); waiting = false; }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() { root.failedAt = Date.now(); }
        function onSupplementaryMessageChanged() { root.waiting = false; }
        function onIsResponseRequiredChanged() { root.waiting = false; root.type(""); }
    }
    onFailedAtChanged: { waiting = false; type(""); }

    PanelWindow {
        id: win

        SpringValue { id: p; target: root.open ? 1 : 0; damping: root.open ? 0.7 : 1.0; stiffness: root.open ? 380 : 460 }
        readonly property real v: p.value
        readonly property real f: Math.max(0, Math.min(1, v))

        screen: Panels.screen
        visible: root.open || v > 0.001
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "nyri-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Colors.m3scrim
            opacity: 0.5 * win.f
        }

        Card {
            id: dialog
            anchors.centerIn: parent
            width: 420
            height: col.implicitHeight + 48
            radius: Shape.extraLarge
            color: Colors.m3surfaceContainerHigh
            elevation: 3
            opacity: win.f
            scale: 0.85 + 0.15 * win.v
            transform: Translate { y: (1 - win.v) * 40 }

            Column {
                id: col
                x: 24
                y: 24
                width: parent.width - 48
                spacing: 16

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72
                    height: 72

                    SpringValue { id: spin; damping: 0.7; stiffness: 120; epsilon: 0.05 }
                    Timer { running: root.waiting; interval: 420; repeat: true; triggeredOnStart: true; onTriggered: spin.target += 72 }

                    MaterialShape {
                        anchors.fill: parent
                        rotation: spin.value
                        shape: root.flow?.supplementaryIsError ? "softBurst" : root.waiting ? "clover4Leaf" : "cookie9Sided"
                        color: root.flow?.supplementaryIsError ? Colors.m3errorContainer : Colors.m3secondaryContainer
                    }
                    MIcon {
                        anchors.centerIn: parent
                        icon: "admin_panel_settings"
                        size: 32
                        fill: 1
                        color: root.flow?.supplementaryIsError ? Colors.m3onErrorContainer : Colors.m3onSecondaryContainer
                    }
                }

                MText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    textStyle: Type.headlineSmall
                    text: "Нужны права администратора"
                }

                MText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    textStyle: Type.bodyMedium
                    color: Colors.m3onSurfaceVariant
                    text: root.flow?.message ?? ""
                }

                Flow {
                    width: parent.width
                    spacing: 6
                    visible: (root.flow?.identities?.length ?? 0) > 1

                    Repeater {
                        model: root.flow?.identities ?? []
                        Chip {
                            required property var modelData
                            readonly property bool picked: root.flow?.selectedIdentity === modelData
                            MText {
                                anchors.verticalCenter: parent.verticalCenter
                                textStyle: Type.labelLarge
                                color: parent.picked ? Colors.m3primary : Colors.m3onSurfaceVariant
                                text: modelData.displayName ?? modelData.name ?? String(modelData)
                            }
                            onClicked: root.flow.selectedIdentity = modelData
                        }
                    }
                }

                Rectangle {
                    id: field
                    width: parent.width
                    height: 56
                    radius: height / 2
                    color: root.flow?.supplementaryIsError ? Colors.m3errorContainer : Colors.m3surfaceContainerHighest
                    visible: root.flow?.isResponseRequired ?? false
                    Behavior on color { ColorAnim {} }

                    SpringValue { id: shake; target: 0; damping: 0.22; stiffness: 900; epsilon: 0.05 }
                    transform: Translate { x: shake.value }
                    Connections {
                        target: root
                        function onFailedAtChanged() { shake.velocity = 900; shake.running = true; }
                    }

                    MIcon {
                        x: 18
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "key"
                        color: Colors.m3onSurfaceVariant
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: !(root.flow?.responseVisible ?? false)
                        Repeater {
                            model: Math.min(root.shapes.length, 14)
                            MaterialShape {
                                required property int index
                                width: 14
                                height: 14
                                shape: root.shapes[root.shapes.length - Math.min(root.shapes.length, 14) + index] ?? "circle"
                                color: Colors.m3primary
                                scale: 0
                                Component.onCompleted: scale = 1
                                Behavior on scale { SpatialAnim { speed: "fast" } }
                            }
                        }
                    }

                    FlowText {
                        anchors.centerIn: parent
                        visible: root.buffer === "" || (root.flow?.responseVisible ?? false)
                        textStyle: Type.bodyLarge
                        color: Colors.m3onSurfaceVariant
                        text: root.flow?.responseVisible && root.buffer !== "" ? root.buffer
                            : root.waiting ? "Проверяю…"
                            : (root.flow?.inputPrompt ?? "Пароль").replace(/:\s*$/, "")
                    }

                    TextInput {
                        id: input
                        width: 0
                        height: 0
                        opacity: 0
                        focus: root.open
                        echoMode: TextInput.Password
                        enabled: !root.waiting
                        onTextChanged: root.type(text)
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.cancel()
                        Connections {
                            target: root
                            function onBufferChanged() { if (root.buffer === "") input.text = "" }
                            function onOpenChanged() { if (root.open) input.forceActiveFocus() }
                        }
                    }
                }

                FlowText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    textStyle: Type.labelLarge
                    color: root.flow?.supplementaryIsError ? Colors.m3error : Colors.m3onSurfaceVariant
                    text: root.flow?.supplementaryMessage ?? ""
                }

                MText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    textStyle: Type.labelSmall
                    color: Colors.m3outline
                    text: root.flow?.actionId ?? ""
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Rectangle {
                        id: cancelBtn
                        width: cancelText.implicitWidth + 32
                        height: 40
                        radius: cancelLayer.pressed ? Shape.small : height / 2
                        color: "transparent"
                        Behavior on radius { SpatialAnim { speed: "fast" } }
                        MText { id: cancelText; anchors.centerIn: parent; textStyle: Type.labelLargeEmph; color: Colors.m3primary; text: "Отмена" }
                        StateLayer { id: cancelLayer; radius: cancelBtn.radius; color: Colors.m3primary; onClicked: root.cancel() }
                    }

                    Rectangle {
                        id: okBtn
                        width: okText.implicitWidth + 40
                        height: 40
                        radius: okLayer.pressed ? Shape.small : height / 2
                        color: root.buffer !== "" ? Colors.m3primary : Colors.m3surfaceContainerHighest
                        Behavior on radius { SpatialAnim { speed: "fast" } }
                        Behavior on color { ColorAnim {} }
                        MText { id: okText; anchors.centerIn: parent; textStyle: Type.labelLargeEmph; color: root.buffer !== "" ? Colors.m3onPrimary : Colors.m3onSurfaceVariant; text: "Разрешить" }
                        StateLayer { id: okLayer; radius: okBtn.radius; color: Colors.m3onPrimary; onClicked: root.submit() }
                    }
                }
            }
        }
    }
}

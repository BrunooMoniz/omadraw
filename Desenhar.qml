import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
    id: root
    property var shell: null
    property var manifest: null
    property bool requested: false
    // The host uses opened to decide whether a second shortcut closes us,
    // including while the screenshot helper is still running.
    readonly property bool opened: requested
    property var targetScreen: null
    property string capturePath: ""
    property string helper: decodeURIComponent(Qt.resolvedUrl("capture.py").toString().replace(/^file:\/\//, ""))
    property string savePayload: ""
    property bool toolbarReady: false
    readonly property alias canvasEditor: editor
    signal dismissed()

    Theme {
        id: currentTheme
        background: Color.popups.background
        foreground: Color.popups.text
        accent: Color.accent
        muted: Color.muted
        border: Color.popups.border
        normalFill: Util.alpha(Style.normalStateColor(Color.popups.text, Color.accent, Color.urgent), Style.normalFillAlpha)
        hoverFill: Util.alpha(Style.hoverStateColor(Color.popups.text, Color.accent, Color.urgent), Style.hoverFillAlpha)
        selectedFill: Util.alpha(Style.selectedStateColor(Color.popups.text, Color.accent, Color.urgent), Style.selectedFillAlpha)
        pressedFill: Util.alpha(Style.pressedStateColor(Color.popups.text, Color.accent, Color.urgent), Style.pressedFillAlpha)
        tooltipBackground: Color.tooltip.background
        tooltipText: Color.tooltip.text
        tooltipBorder: Color.tooltip.border
        fontFamily: Style.font.family
        fontScale: Style.fontScale
        radius: Style.cornerRadius
    }

    function open(payload) {
        if (requested || saving.running) return
        requested = true
        capturing.running = true
    }
    function close() {
        toolbarReady = false
        requested = false
        if (!saving.running) releaseCapture()
    }
    function releaseCapture() {
        editor.imageSource = ""
        if (capturePath) Quickshell.execDetached(["python", helper, "cleanup", capturePath])
        capturePath = ""
    }
    function dismiss() {
        close()
        if (shell && typeof shell.hide === "function") shell.hide("io.github.brunoomoniz.desenhar")
        dismissed()
    }
    function toggle() { if (requested) dismiss(); else open("{}") }
    function state() { return JSON.stringify({opened: opened, requested: requested, ready: editor.imageReady, shapes: editor.shapes.length, saving: saving.running, status: editor.statusText, toolbar: toolbarPanel.visible, palette: currentTheme.dark ? "dark" : "light", theme: {background: String(currentTheme.background), foreground: String(currentTheme.foreground), accent: String(currentTheme.accent), font: currentTheme.fontFamily, radius: currentTheme.radius}}) }
    function error(message) {
        Quickshell.execDetached(["omarchy-notification-send", "Desenhar na tela", message])
    }

    Process {
        id: capturing
        command: ["python", root.helper, "capture"]
        stdout: StdioCollector {
            onStreamFinished: {
                var result
                try { result = JSON.parse(text) } catch (e) { result = {error: "Não foi possível capturar a tela."} }
                if (result.error) { root.dismiss(); root.error(result.error); return }
                if (!root.requested) { Quickshell.execDetached(["python", root.helper, "cleanup", result.path]); return }
                root.targetScreen = Quickshell.screens.find(s => s.name === result.monitor) || Quickshell.screens[0]
                root.capturePath = result.path
                editor.reset()
                editor.imageSource = result.url
            }
        }
    }
    Process {
        id: saving
        command: ["python", root.helper, "save"]
        stdinEnabled: true
        onStarted: { write(root.savePayload); stdinEnabled = false }
        stdout: StdioCollector {
            onStreamFinished: {
                var result
                try { result = JSON.parse(text) } catch (e) { result = {error: "Não foi possível salvar. Seu desenho foi mantido."} }
                editor.statusText = result.error ? "Falha ao salvar: " + result.error : "Salvo em " + result.path
                if (!root.opened) root.error(editor.statusText)
            }
        }
        onExited: { if (!root.requested) root.releaseCapture() }
    }
    PanelWindow {
        id: panel
        property bool focusPrimed: false
        screen: root.targetScreen
        visible: root.requested && editor.imageReady
        anchors { top: true; right: true; bottom: true; left: true }
        exclusionMode: ExclusionMode.Ignore
        color: "#000000"
        WlrLayershell.namespace: "omarchy-desenhar"
        WlrLayershell.layer: WlrLayer.Overlay
        // Match Omarchy's native panels: prime keyboard focus, then release
        // Exclusive's pointer grab so clicks can reach the separate toolbar.
        WlrLayershell.keyboardFocus: visible
            ? (focusPrimed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive)
            : WlrKeyboardFocus.None
        onVisibleChanged: {
            focusPrimed = false
            if (visible) focusPrime.restart()
            else focusPrime.stop()
        }
        Timer { id: focusPrime; interval: 150; onTriggered: panel.focusPrimed = true }
        Editor {
            id: editor
            externalToolbar: true
            theme: currentTheme
            anchors.fill: parent
            saving: saving.running
            onImageReadyChanged: {
                if (imageReady && root.requested) {
                    Qt.callLater(function() {
                        root.toolbarReady = true
                        editor.forceActiveFocus()
                    })
                }
            }
            onCloseRequested: root.dismiss()
            onSaveRequested: drawing => {
                drawing.path = root.capturePath
                root.savePayload = JSON.stringify(drawing)
                saving.stdinEnabled = true
                saving.running = true
            }
        }
    }
    // A separate, tightly sized layer lets the compositor apply the active
    // glass material to controls without processing the screenshot or ink.
    PanelWindow {
        id: toolbarPanel
        screen: root.targetScreen
        visible: panel.visible && root.toolbarReady && editor.toolbarVisible
        anchors { right: !editor.toolbarLeft; left: editor.toolbarLeft }
        margins { left: 20; right: 20 }
        implicitWidth: controls.implicitWidth
        implicitHeight: controls.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "omarchy-desenhar-toolbar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        EditorToolbar { id: controls; editor: root.canvasEditor; anchors.fill: parent }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "Scenes.js" as Scenes

// Synthetic screenshot fixture only. This harness never calls capture().
ShellRoot {
    Desenhar { id: overlay }
    IpcHandler {
        target: "publicDemo"
        function show(): void {
            overlay.targetScreen = Quickshell.screens[0]
            overlay.canvasEditor.reset()
            overlay.canvasEditor.tool = "arrow"
            overlay.requested = true
            overlay.canvasEditor.imageSource = Qt.resolvedUrl("fixture.png")
        }
        function ink(): void { overlay.canvasEditor.commit(Scenes.shapes(overlay.canvasEditor.width / 1600, false)) }
        function state(): string { return overlay.state() }
        function quit(): void { overlay.dismiss(); Qt.quit() }
    }
}

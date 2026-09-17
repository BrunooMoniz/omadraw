import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Desenhar { id: overlay }
    IpcHandler {
        target: "preview"
        function open(): void { overlay.open("{}") }
        function close(): void { overlay.dismiss() }
        function state(): string { return overlay.state() }
        function quit(): void { Qt.quit() }
    }
}

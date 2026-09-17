import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ink.js" as Ink
import "Palette.js" as Palette

Item {
    id: root
    property var theme: fallbackTheme
    Theme { id: fallbackTheme }
    component Label: Text { font.family: root.theme.fontFamily }
    property url imageSource
    property var shapes: []
    property var history: []
    property var future: []
    property var stroke: null
    property string tool: "pen"
    property int colorIndex: 0
    readonly property var inkPalette: theme.dark ? Palette.dark : Palette.light
    readonly property string inkColor: inkPalette[colorIndex]
    property bool externalToolbar: false
    property real inkSize: 4
    property bool toolbarVisible: true
    property bool toolbarLeft: false
    property bool saving: false
    property string statusText: ""
    readonly property bool imageReady: background.status === Image.Ready
    signal saveRequested(var drawing)
    signal closeRequested()

    function reset() {
        shapes = []; history = []; future = []; stroke = null
        toolbarVisible = true; statusText = ""
        ink.requestPaint()
        forceActiveFocus()
    }
    function commit(next) {
        history = history.concat([shapes])
        shapes = next
        future = []
        statusText = ""
        ink.requestPaint()
    }
    function undo() {
        if (!history.length || saving) return
        future = future.concat([shapes])
        shapes = history[history.length - 1]
        history = history.slice(0, -1)
        ink.requestPaint()
    }
    function redo() {
        if (!future.length || saving) return
        history = history.concat([shapes])
        shapes = future[future.length - 1]
        future = future.slice(0, -1)
        ink.requestPaint()
    }
    function clear() {
        if (shapes.length && !saving) commit([])
    }
    function save() {
        if (!saving && imageReady) saveRequested({width: width, height: height, shapes: shapes})
    }
    function point(x, y, constrain) {
        x = Math.max(0, Math.min(width, x))
        y = Math.max(0, Math.min(height, y))
        if (constrain && stroke && (tool === "rectangle" || tool === "ellipse")) {
            var start = stroke.points[0]
            var size = Math.min(Math.abs(x - start.x), Math.abs(y - start.y))
            x = start.x + (x < start.x ? -size : size)
            y = start.y + (y < start.y ? -size : size)
        }
        return {x: x, y: y}
    }

    focus: true
    Keys.onPressed: event => {
        var ctrl = event.modifiers & Qt.ControlModifier
        var shift = event.modifiers & Qt.ShiftModifier
        event.accepted = true
        if (event.key === Qt.Key_Escape) closeRequested()
        else if (event.key === Qt.Key_D && (event.modifiers & Qt.MetaModifier)) closeRequested()
        else if (ctrl && event.key === Qt.Key_Z) { if (shift) redo(); else undo() }
        else if (ctrl && event.key === Qt.Key_Y) redo()
        else if (ctrl && event.key === Qt.Key_S) save()
        else if (event.key === Qt.Key_Tab) toolbarVisible = !toolbarVisible
        else if (event.key === Qt.Key_Delete) clear()
        else if (event.key === Qt.Key_P) tool = "pen"
        else if (event.key === Qt.Key_A) tool = "arrow"
        else if (event.key === Qt.Key_R) tool = "rectangle"
        else if (event.key === Qt.Key_O) tool = "ellipse"
        else event.accepted = false
    }

    Image {
        id: background
        anchors.fill: parent
        source: root.imageSource
        fillMode: Image.Stretch
        cache: false
    }
    Canvas {
        id: ink
        objectName: "ink"
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            for (var i = 0; i < root.shapes.length; i++) Ink.draw(ctx, root.shapes[i])
            if (root.stroke) Ink.draw(ctx, root.stroke)
        }
        Connections {
            target: root
            function onShapesChanged() { ink.requestPaint() }
        }
    }
    MouseArea {
        id: drawing
        objectName: "drawing"
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        enabled: !root.saving
        onPressed: mouse => {
            root.forceActiveFocus()
            root.stroke = {tool: root.tool, color: root.inkColor, size: root.inkSize, points: [root.point(mouse.x, mouse.y, false)]}
            ink.requestPaint()
        }
        onPositionChanged: mouse => {
            if (!pressed || !root.stroke) return
            var p = root.point(mouse.x, mouse.y, mouse.modifiers & Qt.ShiftModifier)
            if (root.stroke.tool === "pen") root.stroke.points.push(p)
            else root.stroke.points = [root.stroke.points[0], p]
            ink.requestPaint()
        }
        onReleased: mouse => {
            if (!root.stroke) return
            var p = root.point(mouse.x, mouse.y, mouse.modifiers & Qt.ShiftModifier)
            if (root.stroke.tool !== "pen") root.stroke.points = [root.stroke.points[0], p]
            else if (root.stroke.points.length > 1) root.stroke.points.push(p)
            if (root.stroke.tool === "pen") root.stroke.points = Ink.smooth(root.stroke.points)
            root.commit(root.shapes.concat([root.stroke]))
            root.stroke = null
            ink.requestPaint()
        }
        onCanceled: { root.stroke = null; ink.requestPaint() }
    }
    EditorToolbar {
        id: toolbar
        editor: root
        visible: !root.externalToolbar && root.toolbarVisible
        x: root.toolbarLeft ? 20 : root.width - width - 20
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        visible: root.statusText !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        width: Math.min(message.implicitWidth + 36, parent.width - 64); height: message.implicitHeight + 24
        radius: root.theme.radius; color: root.theme.panelBackground; border.color: root.theme.border
        Label { id: message; anchors.centerIn: parent; width: parent.width - 36; text: root.statusText; color: root.theme.foreground; font.pixelSize: 13 * root.theme.fontScale; wrapMode: Text.Wrap }
    }
}

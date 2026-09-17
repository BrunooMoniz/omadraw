import QtQuick
import QtTest
import ".."

Item {
    width: 1000; height: 780
    Theme { id: theme; fontFamily: "sans-serif"; fontScale: 1 }
    Editor { id: editor; anchors.fill: parent; theme: theme; imageSource: Qt.resolvedUrl("../evidence/fixture.png") }
    TestCase {
        name: "ThemeChanges"
        when: windowShown
        function test_live_dark_to_light() {
            tryCompare(editor, "imageReady", true)
            theme.background = "#a310120f"
            theme.foreground = "#f4f1ea"
            theme.accent = "#c6f24e"
            theme.radius = 18
            compare(editor.inkColor, "#ff3030")
            editor.commit([{tool: "pen", color: editor.inkColor, size: 4, points: [{x: 100, y: 100}]}])
            waitForRendering(editor)
            var toolbar = findChild(editor, "toolbar")
            var button = findChild(editor, "save")
            var buttonPosition = button.mapToItem(editor, 5, 20)
            var dark = grabImage(editor)
            // The native theme's translucency is preserved over the fixture.
            verify(Math.abs(dark.red(toolbar.x + 10, toolbar.y + 100) - 20) <= 1)
            compare(dark.red(buttonPosition.x, buttonPosition.y), 198)
            compare(toolbar.radius, 18)
            verify(theme.contrast(theme.primaryText, theme.accent) > 4.5)
            theme.accent = "#ff00ff"
            compare(editor.inkColor, "#ff3030")

            theme.background = "#f4f1ea"
            theme.foreground = "#10120f"
            theme.accent = "#23589d"
            theme.radius = 0
            waitForRendering(editor)
            var light = grabImage(editor)
            compare(light.red(toolbar.x + 10, toolbar.y + 100), 244)
            compare(light.blue(buttonPosition.x, buttonPosition.y), 157)
            compare(toolbar.radius, 0)
            compare(button.contentItem.font.family, "sans-serif")
            verify(theme.contrast(theme.primaryText, theme.accent) > 4.5)
            compare(editor.shapes.length, 1)
            compare(editor.inkColor, "#e00000")
            compare(editor.shapes[0].color, "#ff3030")
        }
    }
}

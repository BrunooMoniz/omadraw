import QtQuick
import QtTest
import ".."
import "Scenes.js" as Scenes

Item {
    id: root
    width: 1600; height: 1000
    property bool light: false
    Theme {
        id: theme
        background: root.light ? "#eef4f1ea" : "#e8171b15"
        foreground: root.light ? "#10120f" : "#f4f1ea"
        muted: root.light ? "#687267" : "#97a48e"
        border: root.light ? "#bdc9b6" : "#4a5b3c"
        accent: root.light ? "#23589d" : "#c6f24e"
        radius: 16
        fontFamily: "monospace"
    }
    Workspace { id: scene; anchors.fill: parent; light: root.light }
    Editor { id: editor; anchors.fill: parent; theme: theme; visible: false }
    TestCase {
        name: "PublicDemo"
        when: windowShown
        function test_render_fictional_scenes() {
            for (var mode of ["dark", "light", "glass"]) {
                root.light = mode === "light"
                scene.glassDemo = mode === "glass"
                editor.visible = false
                waitForRendering(scene)
                var background = Qt.resolvedUrl("../evidence/synthetic-" + mode + ".png")
                grabImage(scene).save(background.toString().replace("file://", ""))
                editor.imageSource = background
                tryCompare(editor, "imageReady", true)
                editor.tool = "arrow"
                editor.commit(Scenes.shapes(1, root.light))
                editor.visible = true
                waitForRendering(editor)
                if (mode !== "glass") grabImage(editor).save(Qt.resolvedUrl("../docs/images/" + mode + ".png").toString().replace("file://", ""))
            }
        }
    }
}

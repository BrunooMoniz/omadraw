import QtQuick
import QtTest
import ".."

Item {
    width: 1000; height: 780
    Theme { id: theme; background: "#10120f"; foreground: "white" }
    Editor { id: editor; theme: theme; anchors.fill: parent; imageSource: Qt.resolvedUrl("../evidence/fixture.png") }
    SignalSpy { id: saveSpy; target: editor; signalName: "saveRequested" }
    SignalSpy { id: closeSpy; target: editor; signalName: "closeRequested" }
    TestCase {
        name: "ScreenDrawing"
        when: windowShown
        function init() {
            editor.reset(); editor.tool = "pen"; editor.colorIndex = 0; editor.inkSize = 4
            editor.saving = false; editor.toolbarLeft = false
            saveSpy.clear(); closeSpy.clear()
            waitForRendering(editor)
        }
        function draw(tool) {
            mouseClick(findChild(editor, tool))
            mouseDrag(findChild(editor, "drawing"), 80, 100, 140, 80, Qt.LeftButton)
        }
        function test_tools_and_history() {
            for (var tool of ["pen", "arrow", "rectangle", "ellipse"]) draw(tool)
            compare(editor.shapes.length, 4)
            compare(editor.shapes[3].tool, "ellipse")
            compare(editor.shapes[3].points[1].x, 220)
            mouseClick(findChild(editor, "undo"))
            compare(editor.shapes.length, 3)
            keyClick(Qt.Key_Z, Qt.ControlModifier | Qt.ShiftModifier)
            compare(editor.shapes.length, 4)
            mouseClick(findChild(editor, "clear"))
            compare(editor.shapes.length, 0)
            keyClick(Qt.Key_Z, Qt.ControlModifier)
            compare(editor.shapes.length, 4)
            keyClick(Qt.Key_Z, Qt.ControlModifier)
            draw("pen")
            compare(editor.future.length, 0)
        }
        function test_save_and_close_shortcuts() {
            tryCompare(editor, "imageReady", true)
            draw("rectangle")
            keyClick(Qt.Key_S, Qt.ControlModifier)
            compare(saveSpy.count, 1)
            compare(saveSpy.signalArguments[0][0].shapes.length, 1)
            compare(saveSpy.signalArguments[0][0].width, 1000)
            keyClick(Qt.Key_Escape)
            compare(closeSpy.count, 1)
            mouseClick(findChild(editor, "close"))
            compare(closeSpy.count, 2)
            keyClick(Qt.Key_D, Qt.MetaModifier)
            compare(closeSpy.count, 3)
        }
        function test_square_and_circle_constraint() {
            keyClick(Qt.Key_O)
            var area = findChild(editor, "drawing")
            mousePress(area, 80, 100, Qt.LeftButton, Qt.ShiftModifier)
            mouseMove(area, 220, 180)
            mouseRelease(area, 220, 180, Qt.LeftButton, Qt.ShiftModifier)
            var points = editor.shapes[0].points
            compare(points[1].x - points[0].x, points[1].y - points[0].y)
        }
        function test_toolbar_does_not_draw_and_can_hide() {
            mouseClick(findChild(editor, "toolbar"), 5, 5)
            compare(editor.shapes.length, 0)
            keyClick(Qt.Key_Tab)
            compare(editor.toolbarVisible, false)
            keyClick(Qt.Key_Tab)
            compare(editor.toolbarVisible, true)
        }
        function test_color_size_and_clear_preserve_background() {
            mouseClick(findChild(editor, "color-4")); editor.inkSize = 8
            draw("arrow")
            compare(editor.shapes[0].color, "#00cfff")
            compare(editor.shapes[0].size, 8)
            var original = editor.imageSource
            editor.clear()
            compare(editor.imageSource, original)
            compare(editor.imageReady, true)
        }
        function test_save_blocks_duplicate_and_edit() {
            editor.saving = true
            mouseClick(findChild(editor, "save"))
            keyClick(Qt.Key_S, Qt.ControlModifier)
            compare(saveSpy.count, 0)
            mouseDrag(findChild(editor, "drawing"), 80, 100, 140, 80, Qt.LeftButton)
            compare(editor.shapes.length, 0)
        }
        function test_render_ink_pixels() {
            draw("rectangle")
            waitForRendering(editor)
            var image = grabImage(findChild(editor, "ink"))
            verify(image.red(80, 130) > 230)
            verify(image.green(80, 130) < 150)
            verify(image.red(110, 130) < 50)
        }
        function test_arrow_has_filled_head_and_tapered_tail() {
            keyClick(Qt.Key_A)
            mouseDrag(findChild(editor, "drawing"), 100, 180, 180, 0, Qt.LeftButton)
            waitForRendering(editor)
            var image = grabImage(findChild(editor, "ink"))
            verify(image.red(263, 185) > 230) // inside the filled head
            verify(image.red(120, 182) < 50) // tail tapers instead of staying thick
            verify(image.red(250, 181) > 230) // body grows toward the head
        }
        function test_pen_smooths_corners_preserving_endpoints_and_history() {
            var area = findChild(editor, "drawing")
            mousePress(area, 100, 100)
            mouseMove(area, 140, 160)
            mouseMove(area, 180, 100)
            mouseRelease(area, 180, 100)
            var points = editor.shapes[0].points
            compare(points[0], {x: 100, y: 100})
            compare(points[points.length - 1], {x: 180, y: 100})
            var maxY = Math.max.apply(null, points.map(p => p.y))
            verify(maxY < 160 && maxY > 120)
            editor.undo(); compare(editor.shapes.length, 0)
            editor.redo(); compare(editor.shapes[0].points, points)
        }
    }
}

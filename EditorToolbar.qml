import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: toolbar
    required property var editor
    component ThemedButton: ActionButton { theme: toolbar.editor.theme }
    component Label: Text { font.family: toolbar.editor.theme.fontFamily }
    objectName: "toolbar"
    implicitWidth: Math.min(248 * editor.theme.fontScale, editor.width - 40)
    implicitHeight: Math.min(content.implicitHeight + 36, editor.height - 32)
    color: editor.theme.background
    border.color: editor.theme.border
    radius: editor.theme.radius
    // Absorb clicks in the spaces between controls.
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
    Flickable {
        anchors.fill: parent
        anchors.margins: 18
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: content
            width: parent.width
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Label { text: "OmaDraw"; color: editor.theme.foreground; font.pixelSize: 20 * editor.theme.fontScale; font.weight: Font.DemiBold; Layout.fillWidth: true }
                ThemedButton { text: "⇆"; implicitWidth: 30; implicitHeight: 30; hint: "Move sidebar to the other side"; onClicked: editor.toolbarLeft = !editor.toolbarLeft }
            }
            RowLayout {
                spacing: 6
                Rectangle { width: 5; height: 5; radius: 3; color: editor.theme.accent }
                Label { text: "SCREEN FROZEN"; color: editor.theme.muted; font.pixelSize: 9 * editor.theme.fontScale; font.letterSpacing: 1.1 }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: editor.theme.separator; Layout.topMargin: 2; Layout.bottomMargin: 2 }
            GridLayout {
                columns: 2
                columnSpacing: 8; rowSpacing: 8
                Layout.fillWidth: true
                Repeater {
                    model: [ {tool: "pen", label: "╱  Pen", key: "P"}, {tool: "arrow", label: "↗  Arrow", key: "A"}, {tool: "rectangle", label: "□  Rectangle", key: "R"}, {tool: "ellipse", label: "○  Ellipse", key: "O"} ]
                    ThemedButton {
                        required property var modelData
                        objectName: modelData.tool
                        Layout.fillWidth: true
                        Layout.preferredWidth: 80
                        text: modelData.label
                        hint: modelData.key + " · Shift for a square or circle"
                        selected: editor.tool === modelData.tool
                        onClicked: editor.tool = modelData.tool
                    }
                }
            }
            Label { text: "COLOR"; color: editor.theme.muted; font.pixelSize: 10 * editor.theme.fontScale; font.letterSpacing: 1; Layout.topMargin: 3 }
            GridLayout {
                columns: 5; columnSpacing: 10; rowSpacing: 10
                Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: editor.inkPalette
                    Rectangle {
                        required property string modelData
                        required property int index
                        objectName: "color-" + index
                        width: 30; height: 30; radius: 15
                        color: modelData
                        border.width: editor.colorIndex === index ? 3 : 1
                        border.color: editor.colorIndex === index ? editor.theme.accent : editor.theme.border
                        Label { anchors.centerIn: parent; text: editor.colorIndex === parent.index ? "✓" : ""; color: editor.theme.luminance(parent.color) > 0.4 ? "#101010" : "#ffffff"; font.pixelSize: 15 * editor.theme.fontScale; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editor.colorIndex = parent.index }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 3
                Label { text: "STROKE"; color: editor.theme.muted; font.pixelSize: 10 * editor.theme.fontScale; font.letterSpacing: 1; Layout.fillWidth: true }
                Label { text: editor.inkSize + " px"; color: editor.theme.foreground; font.pixelSize: 11 * editor.theme.fontScale }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 7
                Repeater {
                    model: [2, 4, 8, 12]
                    ThemedButton {
                        required property int modelData
                        Layout.fillWidth: true; Layout.preferredWidth: 30; implicitHeight: 32
                        selected: editor.inkSize === modelData
                        hint: modelData + " pixels"
                        onClicked: editor.inkSize = modelData
                        Rectangle { anchors.centerIn: parent; width: 18; height: parent.modelData; radius: height / 2; color: editor.theme.foreground }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: editor.theme.separator; Layout.topMargin: 2; Layout.bottomMargin: 2 }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ThemedButton { objectName: "undo"; text: "↶  Undo"; Layout.fillWidth: true; enabled: editor.history.length > 0 && !editor.saving; hint: "Ctrl + Z"; onClicked: editor.undo() }
                ThemedButton { objectName: "redo"; text: "↷"; implicitWidth: 42; enabled: editor.future.length > 0 && !editor.saving; hint: "Ctrl + Shift + Z"; onClicked: editor.redo() }
            }
            ThemedButton { objectName: "clear"; text: "Clear drawings"; Layout.fillWidth: true; enabled: editor.shapes.length > 0 && !editor.saving; hint: "Delete · keep the frozen screen"; onClicked: editor.clear() }
            ThemedButton { objectName: "save"; text: editor.saving ? "Saving…" : "Save image"; primary: true; Layout.fillWidth: true; enabled: editor.imageReady && !editor.saving; hint: "Ctrl + S · save without controls"; onClicked: editor.save() }
            ThemedButton { objectName: "close"; text: "Close   Esc"; Layout.fillWidth: true; onClicked: editor.closeRequested() }
            Label { text: "Tab hides the sidebar"; color: editor.theme.muted; font.pixelSize: 10 * editor.theme.fontScale; Layout.alignment: Qt.AlignHCenter }
        }
    }
}

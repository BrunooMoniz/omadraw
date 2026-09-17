import QtQuick
import QtQuick.Controls

Button {
    id: control
    required property var theme
    property bool selected: false
    property bool primary: false
    property string hint: ""
    implicitHeight: 42 * theme.fontScale
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : 0.35
    contentItem: Text {
        text: control.text
        color: control.primary ? control.theme.primaryText : control.selected ? control.theme.accent : control.theme.foreground
        font.family: control.theme.fontFamily
        font.pixelSize: 13 * control.theme.fontScale
        elide: Text.ElideRight
        font.weight: control.primary ? Font.DemiBold : Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: Math.min(9, control.theme.radius)
        color: control.primary ? control.theme.accent : control.down ? control.theme.pressedFill : control.selected ? control.theme.selectedFill : control.hovered ? control.theme.hoverFill : control.theme.normalFill
        border.width: control.selected ? 1 : 0
        border.color: control.theme.accent
    }
    ToolTip {
        visible: control.hovered && control.hint !== ""
        text: control.hint
        delay: 650
        contentItem: Text { text: control.hint; color: control.theme.tooltipText; font.family: control.theme.fontFamily; font.pixelSize: 12 * control.theme.fontScale }
        background: Rectangle { color: control.theme.tooltipBackground; border.color: control.theme.tooltipBorder; radius: Math.min(6, control.theme.radius) }
    }
}

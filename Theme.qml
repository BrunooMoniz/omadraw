import QtQuick

QtObject {
    id: root
    property SystemPalette palette: SystemPalette {}
    property color background: palette.window
    property color foreground: palette.windowText
    property color accent: palette.highlight
    property color muted: palette.mid
    property color border: palette.mid
    property color normalFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.04)
    property color hoverFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
    property color selectedFill: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
    property color pressedFill: Qt.rgba(accent.r, accent.g, accent.b, 0.28)
    property color tooltipBackground: background
    property color tooltipText: foreground
    property color tooltipBorder: border
    // Status messages remain opaque on the frozen image surface.
    readonly property color panelBackground: Qt.rgba(background.r, background.g, background.b, 1)
    property string fontFamily: Qt.application.font.family
    property real fontScale: 1
    property real radius: 12
    readonly property bool dark: luminance(background) < 0.4
    readonly property color separator: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
    readonly property color primaryText: {
        if (root.contrast(root.background, root.accent) >= root.contrast(root.foreground, root.accent))
            return Qt.rgba(root.background.r, root.background.g, root.background.b, 1)
        return Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 1)
    }

    function luminance(color: color): real {
        function channel(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b)
    }
    function contrast(a: color, b: color): real {
        var x = luminance(a), y = luminance(b)
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
    }
}

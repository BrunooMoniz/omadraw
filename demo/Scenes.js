.pragma library
function shapes(scale, light) {
    var colors = light ? ["#7b20d0", "#e00000", "#008ba8", "#e56a00"] : ["#a855ff", "#ff3030", "#00cfff", "#ffdf00"]
    function shape(tool, color, size, coords) {
        return {tool: tool, color: colors[color], size: size * scale, points: coords.map(p => ({x: p[0] * scale, y: p[1] * scale}))}
    }
    return [
        shape("rectangle", 0, 4, [[125, 358], [445, 405]]),
        shape("arrow", 1, 8, [[720, 580], [650, 440]]),
        shape("ellipse", 2, 4, [[835, 353], [1163, 415]]),
        shape("pen", 3, 4, [[146, 683], [175, 689], [207, 684], [242, 689], [278, 684], [318, 689], [361, 684], [398, 688], [437, 684]])
    ]
}

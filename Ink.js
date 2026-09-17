.pragma library

function draw(ctx, shape) {
    var pts = shape.points
    if (!pts.length) return
    var a = pts[0], b = pts[pts.length - 1]
    ctx.strokeStyle = shape.color
    ctx.fillStyle = shape.color
    ctx.lineWidth = shape.size
    ctx.lineCap = "round"
    ctx.lineJoin = "round"
    ctx.beginPath()
    if (shape.tool === "pen") {
        if (pts.length === 1) {
            ctx.arc(a.x, a.y, shape.size / 2, 0, Math.PI * 2)
            ctx.fill()
            return
        }
        ctx.moveTo(a.x, a.y)
        for (var i = 1; i < pts.length; i++) ctx.lineTo(pts[i].x, pts[i].y)
    } else if (shape.tool === "rectangle") {
        ctx.rect(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.abs(b.x - a.x), Math.abs(b.y - a.y))
    } else if (shape.tool === "ellipse") {
        ctx.ellipse(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.abs(b.x - a.x), Math.abs(b.y - a.y))
    } else if (shape.tool === "arrow") {
        var length = Math.hypot(b.x - a.x, b.y - a.y)
        if (length < 0.5) return
        var ux = (b.x - a.x) / length, uy = (b.y - a.y) / length
        var head = Math.min(Math.max(18, shape.size * 5), length * 0.6)
        var half = head / 2
        var neck = Math.min(shape.size * 0.75, half * 0.5)
        var nx = b.x - ux * head, ny = b.y - uy * head
        ctx.moveTo(a.x, a.y)
        ctx.lineTo(nx - uy * neck, ny + ux * neck)
        ctx.lineTo(nx - uy * half, ny + ux * half)
        ctx.lineTo(b.x, b.y)
        ctx.lineTo(nx + uy * half, ny - ux * half)
        ctx.lineTo(nx + uy * neck, ny - ux * neck)
        ctx.closePath(); ctx.fill()
        return
    }
    ctx.stroke()
}

// Corner cutting preserves endpoints and produces the same polyline for screen/export.
function smooth(points) {
    if (points.length < 3) return points
    var result = points
    for (var pass = 0; pass < 2; pass++) {
        var next = [result[0]]
        for (var i = 0; i < result.length - 1; i++) {
            var a = result[i], b = result[i + 1]
            next.push({x: 0.75 * a.x + 0.25 * b.x, y: 0.75 * a.y + 0.25 * b.y})
            next.push({x: 0.25 * a.x + 0.75 * b.x, y: 0.25 * a.y + 0.75 * b.y})
        }
        next.push(result[result.length - 1])
        result = next
    }
    return result
}

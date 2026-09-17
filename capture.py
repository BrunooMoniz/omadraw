#!/usr/bin/env python3
"""Local capture/export helper. Screenshots stay private until explicitly saved."""
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime

import cairo


def runtime_dir():
    root = Path(os.environ["XDG_RUNTIME_DIR"]) / "omarchy-desenhar"
    root.mkdir(mode=0o700, exist_ok=True)
    return root


def capture():
    monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"], timeout=5))
    monitor = next((m for m in monitors if m.get("focused")), monitors[0])
    directory = Path(tempfile.mkdtemp(prefix="session-", dir=runtime_dir()))
    image = directory / "screen.png"
    try:
        subprocess.run(["grim", "-o", monitor["name"], str(image)], check=True, timeout=10)
        os.chmod(image, 0o600)
        return {"path": str(image), "url": image.as_uri(), "monitor": monitor["name"]}
    except Exception:
        shutil.rmtree(directory)
        raise


def cleanup(path):
    directory = Path(path).parent
    if directory.parent == runtime_dir() and directory.name.startswith("session-"):
        shutil.rmtree(directory, ignore_errors=True)


def draw_shape(ctx, shape):
    points = shape["points"]
    if not points:
        return
    color = shape["color"].lstrip("#")
    ctx.set_source_rgb(*(int(color[n:n + 2], 16) / 255 for n in (0, 2, 4)))
    thickness = float(shape["size"])
    ctx.set_line_width(thickness)
    ctx.set_line_cap(cairo.LINE_CAP_ROUND)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    x, y = points[0]["x"], points[0]["y"]
    ex, ey = points[-1]["x"], points[-1]["y"]
    tool = shape["tool"]
    ctx.new_path()
    if tool == "pen":
        if len(points) == 1:
            ctx.arc(x, y, thickness / 2, 0, math.tau)
            ctx.fill()
            return
        ctx.move_to(x, y)
        for point in points[1:]:
            ctx.line_to(point["x"], point["y"])
    elif tool == "rectangle":
        ctx.rectangle(min(x, ex), min(y, ey), abs(ex - x), abs(ey - y))
    elif tool == "ellipse":
        rx, ry = abs(ex - x) / 2, abs(ey - y) / 2
        if rx < 0.1 or ry < 0.1:
            return
        ctx.save()
        ctx.translate((x + ex) / 2, (y + ey) / 2)
        ctx.scale(rx, ry)
        ctx.arc(0, 0, 1, 0, math.tau)
        ctx.restore()
    elif tool == "arrow":
        length = math.hypot(ex - x, ey - y)
        if length < 0.5:
            return
        ux, uy = (ex - x) / length, (ey - y) / length
        head = min(max(18, thickness * 5), length * 0.6)
        half = head / 2
        neck = min(thickness * 0.75, half * 0.5)
        nx, ny = ex - ux * head, ey - uy * head
        ctx.move_to(x, y)
        ctx.line_to(nx - uy * neck, ny + ux * neck)
        ctx.line_to(nx - uy * half, ny + ux * half)
        ctx.line_to(ex, ey)
        ctx.line_to(nx + uy * half, ny - ux * half)
        ctx.line_to(nx + uy * neck, ny - ux * neck)
        ctx.close_path()
        ctx.fill()
        return
    else:
        raise ValueError("Ferramenta desconhecida")
    ctx.stroke()


def render(payload):
    surface = cairo.ImageSurface.create_from_png(payload["path"])
    ctx = cairo.Context(surface)
    ctx.scale(surface.get_width() / payload["width"], surface.get_height() / payload["height"])
    for shape in payload["shapes"]:
        draw_shape(ctx, shape)
    return surface


def pictures_dir():
    override = os.environ.get("OMARCHY_SCREENSHOT_DIR")
    if override:
        return Path(override).expanduser()
    result = subprocess.run(["xdg-user-dir", "PICTURES"], capture_output=True, text=True, timeout=5)
    return Path(result.stdout.strip()) if result.returncode == 0 and result.stdout.strip() else Path.home() / "Pictures"


def save(payload, directory=None):
    surface = render(payload)
    directory = Path(directory) if directory else pictures_dir() / "Anotacoes"
    directory.mkdir(parents=True, exist_ok=True)
    name = "anotacao-" + datetime.now().strftime("%Y-%m-%d_%H-%M-%S-%f") + ".png"
    destination = directory / name
    # Publish only the completed image, with private permissions.
    fd, temporary = tempfile.mkstemp(prefix=".anotacao-", dir=directory)
    try:
        with os.fdopen(fd, "wb") as stream:
            surface.write_to_png(stream)
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    return {"path": str(destination)}


def main():
    try:
        action = sys.argv[1]
        if action == "capture":
            result = capture()
        elif action == "save":
            result = save(json.load(sys.stdin))
        elif action == "cleanup":
            cleanup(sys.argv[2])
            result = {}
        else:
            raise ValueError("Ação desconhecida")
        print(json.dumps(result))
    except Exception as error:
        print(json.dumps({"error": str(error)}))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

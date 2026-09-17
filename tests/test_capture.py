import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cairo
import capture


class ExportTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.base = Path(self.directory.name) / "base.png"
        surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 400, 240)
        ctx = cairo.Context(surface)
        ctx.set_source_rgb(1, 1, 1)
        ctx.paint()
        surface.write_to_png(str(self.base))
        self.payload = {"path": str(self.base), "width": 200, "height": 120, "shapes": []}

    def shape(self, tool, start, end):
        return {"tool": tool, "color": "#ff0000", "size": 4, "points": [dict(zip(("x", "y"), start)), dict(zip(("x", "y"), end))]}

    def pixel(self, surface, x, y):
        surface.flush()
        offset = y * surface.get_stride() + x * 4
        return tuple(surface.get_data()[offset:offset + 3])

    def test_shapes_scale_to_native_pixels_without_toolbar(self):
        self.payload["shapes"] = [self.shape("rectangle", (10, 10), (50, 40)), self.shape("ellipse", (60, 10), (100, 40)), self.shape("arrow", (15, 60), (75, 60)), self.shape("pen", (100, 70), (140, 90))]
        surface = capture.render(self.payload)
        self.assertEqual((surface.get_width(), surface.get_height()), (400, 240))
        for x, y in [(20, 40), (160, 20), (80, 120), (240, 160)]:
            self.assertEqual(self.pixel(surface, x, y), (0, 0, 255), (x, y))
        for x, y in [(50, 50), (160, 50), (390, 30)]:
            self.assertEqual(self.pixel(surface, x, y), (255, 255, 255), (x, y))

    def test_reverse_drag_and_single_dot(self):
        rectangle = self.shape("rectangle", (50, 40), (10, 10))
        dot = self.shape("pen", (80, 50), (80, 50))
        dot["points"].pop()
        self.payload["shapes"] = [rectangle, dot]
        surface = capture.render(self.payload)
        self.assertEqual(self.pixel(surface, 20, 40), (0, 0, 255))
        self.assertEqual(self.pixel(surface, 160, 100), (0, 0, 255))

    def test_arrow_has_filled_head_and_tapered_tail_in_both_directions(self):
        for start, end in [((10, 60), (100, 60)), ((100, 60), (10, 60))]:
            with self.subTest(start=start):
                self.payload["shapes"] = [self.shape("arrow", start, end)]
                surface = capture.render(self.payload)
                forward = start[0] < end[0]
                head_x, body_x, tail_x = (83, 74, 20) if forward else (27, 36, 90)
                self.assertEqual(self.pixel(surface, head_x * 2, 65 * 2), (0, 0, 255))
                self.assertEqual(self.pixel(surface, body_x * 2, 61 * 2), (0, 0, 255))
                self.assertEqual(self.pixel(surface, tail_x * 2, 62 * 2), (255, 255, 255))

    def test_zero_length_arrow_is_empty_and_short_arrow_stays_bounded(self):
        self.payload["shapes"] = [self.shape("arrow", (80, 60), (80, 60))]
        self.assertEqual(self.pixel(capture.render(self.payload), 160, 120), (255, 255, 255))
        self.payload["shapes"] = [self.shape("arrow", (80, 60), (83, 60))]
        surface = capture.render(self.payload)
        for x, y in [(158, 120), (168, 120), (162, 124), (162, 116)]:
            self.assertEqual(self.pixel(surface, x, y), (255, 255, 255))

    def test_save_is_private_unique_and_preserves_source(self):
        original = self.base.read_bytes()
        self.payload["shapes"] = [self.shape("arrow", (15, 60), (75, 60))]
        first = Path(capture.save(self.payload, self.directory.name)["path"])
        second = Path(capture.save(self.payload, self.directory.name)["path"])
        self.assertNotEqual(first, second)
        self.assertEqual(first.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.base.read_bytes(), original)
        self.assertEqual(self.pixel(cairo.ImageSurface.create_from_png(str(first)), 80, 120), (0, 0, 255))

    def test_clear_export_matches_original(self):
        self.assertEqual(self.pixel(capture.render(self.payload), 80, 120), (255, 255, 255))

    def test_failed_export_keeps_source(self):
        self.payload["path"] = "/missing/screenshot.png"
        with self.assertRaises(cairo.Error):
            capture.save(self.payload, self.directory.name)
        self.assertTrue(self.base.exists())

    def test_cleanup_only_owns_session_directory(self):
        with patch.dict(os.environ, {"XDG_RUNTIME_DIR": self.directory.name}):
            session = capture.runtime_dir() / "session-test"
            session.mkdir()
            image = session / "screen.png"
            image.touch()
            capture.cleanup(str(self.base))
            self.assertTrue(self.base.exists())
            capture.cleanup(str(image))
            self.assertFalse(session.exists())

    def test_capture_failure_removes_partial_screenshot(self):
        with patch.dict(os.environ, {"XDG_RUNTIME_DIR": self.directory.name}), patch.object(capture.subprocess, "check_output", return_value=json.dumps([{"name": "eDP-1", "focused": True}]).encode()), patch.object(capture.subprocess, "run", side_effect=RuntimeError("capture failed")):
            with self.assertRaises(RuntimeError):
                capture.capture()
            self.assertEqual(list(capture.runtime_dir().iterdir()), [])


if __name__ == "__main__":
    unittest.main()

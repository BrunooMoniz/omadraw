"""Exercise the optional glass registration without changing the real desktop."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class CompositorTests(unittest.TestCase):
    def test_registration_respects_system_glass_and_isolates_capture(self):
        source = Path(__file__).resolve().parents[1] / "compositor.lua"
        for enabled, available in [(False, True), (True, False), (True, True)]:
            with self.subTest(enabled=enabled, available=available), tempfile.TemporaryDirectory() as home:
                flag = Path(home) / ".local/state/omarchy/liquid-glass-install/enabled"
                flag.parent.mkdir(parents=True)
                flag.write_text(str(enabled).lower())
                harness = '''
local rules, surfaces = {}, {}
hl = {plugin = {}, layer_rule = function(rule) table.insert(rules, rule) end}
if arg[2] == "yes" then
  hl.plugin.hyprglass = {layer = function(ns, opts) surfaces[ns] = opts end}
end
dofile(arg[1])
assert(rules[1].no_anim == true)
if arg[3] == "yes" then
  assert(#rules == 2)
  assert(rules[2].match.namespace == "^omarchy-desenhar-toolbar$")
  assert(surfaces["omarchy-desenhar-toolbar"].mask_threshold == 0.25)
  assert(surfaces["omarchy-desenhar-toolbar"].preset == nil)
  assert(surfaces["omarchy-desenhar"].exclude == true)
else
  assert(#rules == 1)
  assert(next(surfaces) == nil)
end
'''
                subprocess.run(["lua", "-", str(source), "yes" if available else "no", "yes" if enabled and available else "no"],
                               input=harness, text=True, check=True, env={**os.environ, "HOME": home})


if __name__ == "__main__":
    unittest.main()

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ID = "io.github.brunoomoniz.desenhar"


class ShortcutSetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bindings = self.home / ".config/hypr/bindings.lua"
        self.bindings.parent.mkdir(parents=True)
        self.original = '-- existing user bindings\no.bind("SUPER + X", "Example", "example")\n'
        self.bindings.write_text(self.original)
        plugin = self.home / ".config/omarchy/plugins" / ID
        plugin.mkdir(parents=True)
        (plugin / "compositor.lua").write_text('-- installed fixture\n')
        commands = self.home / 'bin'
        commands.mkdir()
        hyprctl = commands / 'hyprctl'
        hyprctl.write_text('''#!/usr/bin/env python
import os,sys,json
from pathlib import Path
root=Path(os.environ['HOME'])
if sys.argv[1]=='binds': print(os.environ.get('TEST_BINDS','[]'))
elif sys.argv[1]=='reload':
 (root/'reloaded').touch()
 if os.environ.get('TEST_FAILURE')=='reload': sys.exit(1)
elif sys.argv[1]=='configerrors' and (root/'reloaded').exists():
 if os.environ.get('TEST_FAILURE')=='errors': print('fixture config error')
 if os.environ.get('TEST_FAILURE')=='validation': sys.exit(1)
''')
        hyprctl.chmod(0o755)
        for name in ['grim', 'qs', 'omarchy', 'omarchy-shell', 'xdg-user-dir']:
            stub = commands / name
            stub.write_text('#!/bin/sh\nexit 99\n')
            stub.chmod(0o755)
        self.env = {**os.environ, 'HOME': str(self.home), 'PATH': str(commands) + ':' + os.environ['PATH']}

    def setup_shortcut(self):
        return subprocess.run([str(ROOT / 'install.sh')], env=self.env, capture_output=True, text=True)

    def test_installed_plugin_setup_preserves_bindings_and_is_idempotent(self):
        first = self.setup_shortcut()
        self.assertEqual(first.returncode, 0, first.stderr)
        updated = self.bindings.read_text()
        self.assertTrue(updated.startswith(self.original))
        self.assertIn('SUPER + D', updated)
        self.assertIn('compositor.lua', updated)
        backups = list(self.bindings.parent.glob('bindings.lua.before-desenhar.*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), self.original)
        second = self.setup_shortcut()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(self.bindings.read_text(), updated)

    def test_collision_leaves_configuration_untouched(self):
        self.env['TEST_BINDS'] = json.dumps([{'modmask': 64, 'key': 'D'}])
        self.assertNotEqual(self.setup_shortcut().returncode, 0)
        self.assertEqual(self.bindings.read_text(), self.original)
        self.assertFalse((self.home / 'reloaded').exists())

    def test_failed_reload_or_validation_restores_configuration(self):
        for failure in ['reload', 'validation', 'errors']:
            with self.subTest(failure=failure):
                (self.home / 'reloaded').unlink(missing_ok=True)
                self.env['TEST_FAILURE'] = failure
                self.assertNotEqual(self.setup_shortcut().returncode, 0)
                self.assertEqual(self.bindings.read_text(), self.original)

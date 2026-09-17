#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
plugin_id=io.github.brunoomoniz.desenhar
# Omarchy's plugin CLI currently installs under HOME/.config.
config_dir="$HOME/.config"
bindings="$config_dir/hypr/bindings.lua"
plugin_dir="$config_dir/omarchy/plugins/$plugin_id"

for binary in python grim hyprctl qs omarchy omarchy-shell xdg-user-dir rg; do
  command -v "$binary" >/dev/null || { echo "Missing dependency: $binary" >&2; exit 1; }
done
python -c 'import cairo'
[[ -f $bindings ]] || { echo "Hyprland Lua configuration was not found." >&2; exit 1; }
[[ -z $(hyprctl configerrors) ]] || { echo "Resolve existing Hyprland configuration errors before setup." >&2; exit 1; }
if rg -q --fixed-strings -- "-- >>> $plugin_id >>>" "$bindings"; then
  echo "Super + D is already configured. No changes made."
  exit 0
fi
hyprctl binds -j | python -c '
import json,sys
if any(b.get("modmask") == 64 and str(b.get("key", "")).upper() == "D" for b in json.load(sys.stdin)):
    sys.exit("Super + D is already in use; no shortcuts were replaced.")'
if [[ ! -e $plugin_dir ]]; then
  [[ -z $(git status --porcelain) ]] || { echo "Test and commit source changes before installing." >&2; exit 1; }
  omarchy plugin add "$PWD" --enable --yes
fi
[[ -f $plugin_dir/compositor.lua ]] || { echo "Incomplete installation: compositor.lua is missing." >&2; exit 1; }

backup="$bindings.before-desenhar.$(date +%Y%m%d-%H%M%S)"
cp -p -- "$bindings" "$backup"
python - "$bindings" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
with p.open('a') as stream:
    stream.write('''
-- >>> io.github.brunoomoniz.desenhar >>>
o.bind("SUPER + D", "OmaDraw", "omarchy-shell shell toggle io.github.brunoomoniz.desenhar")
local desenhar = os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.brunoomoniz.desenhar/compositor.lua"
local desenhar_file = io.open(desenhar, "r")
if desenhar_file then desenhar_file:close(); dofile(desenhar) end
-- <<< io.github.brunoomoniz.desenhar <<<
''')
PY
rollback() {
  cp -p -- "$backup" "$bindings"
  hyprctl reload >/dev/null || true
}
if ! hyprctl reload >/dev/null; then
  rollback
  echo "Hyprland reload failed; previous shortcuts restored." >&2
  exit 1
fi
if ! errors=$(hyprctl configerrors); then
  rollback
  echo "Hyprland validation failed; previous shortcuts restored." >&2
  exit 1
fi
if [[ -n $errors ]]; then
  rollback
  printf 'Setup stopped and previous shortcuts restored: %s\n' "$errors" >&2
  exit 1
fi
echo "Configured: Super + D. Shortcut backup: $backup"

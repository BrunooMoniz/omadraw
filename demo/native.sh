#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
[[ -f evidence/synthetic-glass.png ]] || { echo "Render demo/preview.qml first." >&2; exit 1; }
preview_dir=$(mktemp -d "${XDG_RUNTIME_DIR:?}/desenhar-public-demo.XXXXXX")
trap 'rm -rf -- "$preview_dir"' EXIT
for source_file in *.qml *.js capture.py; do ln -s "$PWD/$source_file" "$preview_dir/$source_file"; done
ln -s "${OMARCHY_PATH:-/usr/share/omarchy}/shell/Commons" "$preview_dir/Commons"
ln -s "$PWD/evidence/synthetic-glass.png" "$preview_dir/fixture.png"
ln -s "$PWD/demo/Scenes.js" "$preview_dir/Scenes.js"
cp demo/native.qml "$preview_dir/shell.qml"
printf '%s\n' "$preview_dir"
qs -p "$preview_dir" --no-color

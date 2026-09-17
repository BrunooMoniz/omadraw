#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
preview_dir=$(mktemp -d "${XDG_RUNTIME_DIR:?}/desenhar-preview.XXXXXX")
trap 'rm -rf -- "$preview_dir"' EXIT
for source_file in *.qml *.js capture.py; do
  ln -s "$PWD/$source_file" "$preview_dir/$source_file"
done
ln -s "${OMARCHY_PATH:-/usr/share/omarchy}/shell/Commons" "$preview_dir/Commons"
cp preview.qml "$preview_dir/shell.qml"
printf 'Prévia isolada: %s\n' "$preview_dir"
qs -p "$preview_dir" --no-color

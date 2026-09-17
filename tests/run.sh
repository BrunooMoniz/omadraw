#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
mkdir -p evidence
chmod 700 evidence
python - <<'PY'
import cairo
s = cairo.ImageSurface(cairo.FORMAT_ARGB32, 1000, 780)
c = cairo.Context(s)
c.set_source_rgb(.1, .13, .19)
c.paint()
s.write_to_png('evidence/fixture.png')
PY
python -m unittest discover -s tests -p 'test_*.py' -v
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests
bash -n install.sh
git diff --check

# Public demonstration assets

`Workspace.qml` contains only fictional text and code-drawn shapes. `Scenes.js` supplies the annotations. `preview.qml` renders the actual editor in dark/light themes. No personal screenshot is an input.

From the repository root:

```bash
mkdir -p evidence docs/images
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib/qt6/bin/qmltestrunner -input demo/preview.qml
```

For a native Liquid Glass demonstration, first activate your existing compatible glass setup and run `./demo/native.sh`. The harness prints its runtime path. Its `publicDemo` IPC target exposes `show`, `ink`, `state` and `quit`; `show` injects the generated `evidence/synthetic-glass.png` directly into the editor. It never invokes the capture helper. Wait for `state` to report `ready` and `toolbar`, call `ink`, capture only that output while the opaque synthetic image covers it, then call `quit`.

Always inspect demonstration images before publishing. Strip metadata from PNGs. Do not substitute real desktop captures or files from local development evidence.

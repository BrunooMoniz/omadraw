# Validation

Release preparation checks:

- 13 Python test cases passed, including native-scale export, filled arrows in both directions, short/degenerate arrows, private PNG permissions, unique saves, capture failure cleanup, optional compositor registration, shortcut collision detection, repeat setup and rollback after failed reload/validation.
- 10 Qt test cases passed (14 reported entries including setup/teardown), covering mouse/keyboard drawing, shape constraints, undo/redo, clear, save, sidebar interaction, pen smoothing, rendered pixels and dark/light theme changes without recoloring existing annotations.
- The real Hyprland/Wayland path was exercised at 1.6 scale: Super+D open/close, separate toolbar clicks, drawing, save, hide/show, moving the toolbar and temporary capture cleanup.
- Native PNG output was 2880 × 1800 with no toolbar. A pixel comparison with only the toolbar's glass participation toggled showed changes on the toolbar and no changes in the compared frozen canvas region.
- Demonstration assets are reproducible from fictional source content. Dark/light images render the actual editor components; the optional glass image uses the compositor over an injected synthetic image.

`./tests/run.sh` runs the durable automated coverage. `omarchy plugin validate .` validates the installed Omarchy manifest contract. A standalone real desktop session is needed for native compositor checks; the offscreen Qt tests do not prove compositor effects.

Physical multi-monitor and rotated-output layouts have not been verified. The UI is currently in Brazilian Portuguese.

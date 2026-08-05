---
name: deraster-icon
description: Replace an embedded base64 raster in an SVG icon with a pure-vector approximation, leaving no binary image data. Use when an icon.svg fails validation for an embedded image, or when a mesh-gradient icon must stay real SVG.
---
# Deraster icon

`mesh_gradient.py` in this folder redraws each embedded `<image>` as blurred sampled-color rects — visually identical at icon size, and typically 900KB+ → 40–60KB. Its `--help` documents both modes (`deraster`, `from-png`) and every flag; read it before deviating from the run below.

## Workflow

1. Run the conversion with the visual check:
   ```bash
   python3 ~/.claude/skills/deraster-icon/mesh_gradient.py deraster path/to/icon.svg --check
   ```
   This overwrites the input in place (`-o` writes elsewhere).
2. Judge the result. `--check` prints a mean/max pixel diff — under ~3/255 reads as identical at icon size. When Chrome/Chromium is missing the run is diff-less: render both files yourself, or have the user eyeball them, before the job counts as done.
3. Report the byte-size drop and the pixel diff.

## High diff

Visible banding or a plainly wrong color traces to the source `<image>` tag — an offset x/y, an extra transform, non-square dimensions — so inspect its attributes first. Tune only after that: the defaults (`--grid 28 --blur 20 --cell-scale 1.6`) are calibrated against a real Illustrator mesh-gradient export; raise `--grid` first and lower `--blur` proportionally. The same lever shrinks an oversized output from a very high-res source.

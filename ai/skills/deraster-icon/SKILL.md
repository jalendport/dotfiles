---
name: deraster-icon
description: Strip an embedded raster (base64 PNG/JPG mesh gradient, typically from an Illustrator or Figma export) out of an SVG icon and replace it with a pure-vector approximation, so the file has no binary image data. Use when a plugin/app icon.svg fails validation for containing an embedded image, or when the user wants a "cool gradient" icon kept as real SVG.
---

Some design tools (Illustrator gradient meshes, some Figma exports) bake complex multi-color gradients into an SVG as an embedded base64 `<image>`, because SVG has no native mesh-gradient primitive. Marketplaces that scan for embedded binaries (e.g. the Craft CMS plugin store) reject these.

`mesh_gradient.py` in this skill folder fixes that by sampling the raster on a grid and re-drawing it as blurred vector rects — visually indistinguishable at icon size, zero embedded bytes, and far smaller (typically 900KB+ → 40-60KB).

## Usage

```bash
python3 ~/.claude/skills/deraster-icon/mesh_gradient.py deraster path/to/icon.svg --check
```

This overwrites `icon.svg` in place, finds every embedded `<image>` (base64 data URI), and replaces each with a `<g filter="feGaussianBlur">` of sampled-color rects — preserving any `id`/`transform` so existing `<use>` references keep working untouched. `--check` renders the before/after through headless Chrome and reports the mean/max pixel diff (anything under ~3/255 is imperceptible at icon size).

Pass `-o other.svg` to write elsewhere instead of overwriting. Defaults (`--grid 28 --blur 20 --cell-scale 1.6`) were tuned against a real Illustrator mesh-gradient export and read as pixel-perfect; only touch them if `--check` reports a high diff (bump `--grid` up first, then reduce `--blur` proportionally) or the output file is unacceptably large for very high-res sources.

There's also a `from-png` mode for building a gradient snippet from a standalone raster instead of extracting one from an existing SVG:

```bash
python3 ~/.claude/skills/deraster-icon/mesh_gradient.py from-png gradient.png --size 800 -o snippet.svg
```

## Workflow when invoked

1. Run `deraster` with `--check` on the target file.
2. Read the reported byte-size drop and pixel diff back to the user.
3. If Chrome/Chromium isn't available for `--check`, render both files yourself (or ask the user to eyeball it) before calling the job done — don't just trust the diff-less run.
4. If the diff looks off (visible banding, a color that's clearly wrong), it's almost always because the source `<image>` had an unusual attribute layout (offset x/y, an extra transform, non-square dimensions) — inspect the raw `<image ...>` tag's attributes rather than tweaking grid/blur blindly.

#!/usr/bin/env python3
"""
Replace embedded raster images (mesh-gradient exports from Illustrator/Figma,
etc.) inside an SVG with a pure-vector approximation: a grid of solid-color
rects sampled from the source raster, softened with an SVG <feGaussianBlur>
filter. No base64/binary data ends up in the output.

Usage:
    mesh_gradient.py deraster icon.svg -o icon.svg [--grid 28] [--blur 20] [--check]
    mesh_gradient.py from-png gradient.png --size 800 -o snippet.svg [--check]

`deraster` finds every embedded <image> (base64 data URI) in the input SVG,
generates a mesh-blur approximation sized to match, and splices it back in
place — preserving id/transform so any <use> elements keep working untouched.

`from-png` takes a standalone raster and emits a self-contained SVG (a <g>
with the filter + rects) at the given pixel size, for building new gradients
from reference art rather than extracting one from an existing file.

--check renders the before/after through headless Chrome and reports the
mean/max pixel diff, so you don't have to eyeball it.
"""

import argparse
import base64
import io
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageChops
except ImportError:
    sys.exit("Missing dependency: pip3 install --user pillow")

IMAGE_TAG_RE = re.compile(r"<image\b[^>]*?/>", re.DOTALL)
ATTR_RE = re.compile(r'([\w:.-]+)\s*=\s*"([^"]*)"')
DEFS_OPEN_RE = re.compile(r"<defs\b[^>]*>")
SVG_CLOSE_RE = re.compile(r"</svg\s*>")
CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    shutil.which("google-chrome") or "",
    shutil.which("chromium") or "",
    shutil.which("chromium-browser") or "",
]


def parse_attrs(tag_text):
    return dict(ATTR_RE.findall(tag_text))


def decode_data_uri(href):
    m = re.match(r"data:image/(\w+);base64,(.+)", href, re.DOTALL)
    if not m:
        return None
    return base64.b64decode(m.group(2))


def strip_px(value, default):
    if value is None:
        return default
    return float(value.rstrip("px"))


def build_mesh_rects(im, out_w, out_h, grid, cell_scale):
    src_w, src_h = im.size
    cell_w = out_w / grid
    cell_h = out_h / grid
    rects = []
    for gy in range(grid):
        for gx in range(grid):
            cx = (gx + 0.5) * cell_w
            cy = (gy + 0.5) * cell_h
            sx = min(int(cx / out_w * src_w), src_w - 1)
            sy = min(int(cy / out_h * src_h), src_h - 1)
            r, g, b = im.getpixel((sx, sy))[:3]
            rw, rh = cell_w * cell_scale, cell_h * cell_scale
            x, y = cx - rw / 2, cy - rh / 2
            rects.append(
                f'<rect x="{x:.1f}" y="{y:.1f}" width="{rw:.1f}" height="{rh:.1f}" '
                f'fill="#{r:02x}{g:02x}{b:02x}"/>'
            )
    return "".join(rects)


def mesh_group(im, out_w, out_h, filter_id, grid, blur, cell_scale):
    rects = build_mesh_rects(im, out_w, out_h, grid, cell_scale)
    filter_def = (
        f'<filter id="{filter_id}" x="-20%" y="-20%" width="140%" height="140%">'
        f'<feGaussianBlur stdDeviation="{blur}"/></filter>'
    )
    group = f'<g filter="url(#{filter_id})">{rects}</g>'
    return filter_def, group


def inject_defs(svg_text, filter_defs):
    if not filter_defs:
        return svg_text
    joined = "".join(filter_defs)
    m = DEFS_OPEN_RE.search(svg_text)
    if m:
        return svg_text[: m.end()] + joined + svg_text[m.end() :]
    m = SVG_CLOSE_RE.search(svg_text)
    return svg_text[: m.start()] + f"<defs>{joined}</defs>" + svg_text[m.start() :]


def deraster(input_path, output_path, grid, blur, cell_scale):
    before = input_path.stat().st_size
    svg_text = input_path.read_text()
    filter_defs = []
    counter = 0

    def replace(match):
        nonlocal counter
        tag = match.group(0)
        attrs = parse_attrs(tag)
        href = attrs.get("xlink:href") or attrs.get("href")
        if not href or not href.startswith("data:image/"):
            return tag  # not embedded raster (e.g. an external href) — leave alone

        raw = decode_data_uri(href)
        if raw is None:
            return tag
        im = Image.open(io.BytesIO(raw)).convert("RGB")

        w = strip_px(attrs.get("width"), im.width)
        h = strip_px(attrs.get("height"), im.height)
        counter += 1
        filter_id = f"_meshBlur{counter}"
        filter_def, group = mesh_group(im, w, h, filter_id, grid, blur, cell_scale)
        filter_defs.append(filter_def)

        img_id = attrs.get("id")
        if img_id:
            # Preserve the id so existing <use xlink:href="#id"> keeps working.
            return f'<g id="{img_id}">{group}</g>'

        # Standalone inline image: preserve its own position/transform.
        x, y = strip_px(attrs.get("x"), 0), strip_px(attrs.get("y"), 0)
        transform = attrs.get("transform", "")
        outer_transform = f'translate({x},{y}) {transform}'.strip()
        return f'<g transform="{outer_transform}">{group}</g>'

    new_svg = IMAGE_TAG_RE.sub(replace, svg_text)
    new_svg = inject_defs(new_svg, filter_defs)

    if counter == 0:
        print("No embedded raster <image> elements found — nothing to do.", file=sys.stderr)
        return False

    output_path.write_text(new_svg)
    after = output_path.stat().st_size
    print(f"Replaced {counter} embedded image(s). {before:,} bytes -> {after:,} bytes.")
    return True


def from_png(png_path, size, grid, blur, cell_scale, output_path):
    im = Image.open(png_path).convert("RGB")
    filter_def, group = mesh_group(im, size, size, "_meshBlur1", grid, blur, cell_scale)
    svg = (
        f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" '
        f'xmlns="http://www.w3.org/2000/svg">'
        f"<defs>{filter_def}</defs>{group}</svg>\n"
    )
    output_path.write_text(svg)
    print(f"Wrote {output_path} ({output_path.stat().st_size:,} bytes)")


def find_chrome():
    for path in CHROME_CANDIDATES:
        if path and Path(path).exists():
            return path
    return None


def render_svg(chrome, svg_path, png_out, dim):
    subprocess.run(
        [
            chrome,
            "--headless",
            "--disable-gpu",
            f"--screenshot={png_out}",
            f"--window-size={dim},{dim}",
            "--default-background-color=ffffffff",
            f"file://{svg_path.resolve()}",
        ],
        capture_output=True,
        check=True,
    )


def check_fidelity(before_path, after_path, dim=800):
    chrome = find_chrome()
    if not chrome:
        print("(--check skipped: no Chrome/Chromium found)", file=sys.stderr)
        return
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        a_png, b_png = tmp / "a.png", tmp / "b.png"
        render_svg(chrome, before_path, a_png, dim)
        render_svg(chrome, after_path, b_png, dim)
        a = Image.open(a_png).convert("RGB")
        b = Image.open(b_png).convert("RGB").resize(a.size)
        diff = ImageChops.difference(a, b)
        pixels = list(diff.getdata())
        mean = sum(sum(p) for p in pixels) / (len(pixels) * 3)
        worst = max(max(p) for p in pixels)
        print(f"Fidelity check: mean channel diff {mean:.2f}/255, max {worst}/255 "
              f"(<3 is essentially imperceptible)")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    d = sub.add_parser("deraster", help="Strip embedded raster(s) out of an SVG")
    d.add_argument("input", type=Path)
    d.add_argument("-o", "--output", type=Path, help="defaults to overwriting input")
    d.add_argument("--grid", type=int, default=28)
    d.add_argument("--blur", type=float, default=20)
    d.add_argument("--cell-scale", type=float, default=1.6)
    d.add_argument("--check", action="store_true", help="render before/after and report pixel diff")

    f = sub.add_parser("from-png", help="Build a mesh-gradient SVG snippet from a raw PNG/JPG")
    f.add_argument("input", type=Path)
    f.add_argument("--size", type=int, default=800)
    f.add_argument("-o", "--output", type=Path, required=True)
    f.add_argument("--grid", type=int, default=28)
    f.add_argument("--blur", type=float, default=20)
    f.add_argument("--cell-scale", type=float, default=1.6)

    args = p.parse_args()

    if args.cmd == "deraster":
        output = args.output or args.input
        # Need the pristine original for --check, so snapshot before overwriting in place.
        original_snapshot = None
        if args.check and output == args.input:
            # Keep the .svg extension so Chrome renders the snapshot as SVG, not plain text.
            original_snapshot = args.input.with_name(args.input.stem + ".orig-check" + args.input.suffix)
            shutil.copy(args.input, original_snapshot)
        ok = deraster(args.input, output, args.grid, args.blur, args.cell_scale)
        if ok and args.check:
            before = original_snapshot or args.input
            check_fidelity(before, output)
            if original_snapshot:
                original_snapshot.unlink()
    else:
        from_png(args.input, args.size, args.grid, args.blur, args.cell_scale, args.output)


if __name__ == "__main__":
    main()

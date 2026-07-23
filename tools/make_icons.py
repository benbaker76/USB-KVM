#!/usr/bin/env python3
"""Generate the raster icon assets from the checked-in SVG masters.

Three SVGs are the single source of truth for all icon artwork:

  assets/icon.svg                            full-colour application icon
  Linux/gnome-extension/icons/usbkvm-symbolic.svg        tray/panel, connected
  Linux/gnome-extension/icons/usbkvm-error-symbolic.svg  tray/panel, no device

The symbolic SVGs paint with `currentColor` so GNOME can tint them per theme;
here that is resolved by injecting a CSS `color` onto the root element before
rendering — black for light taskbars, white for dark ones. Every size in a tray
.ico is rendered natively from the vector rather than resampled from one bitmap,
which keeps the 16px and 20px frames — the ones the tray actually shows — crisp.

The SVGs themselves are hand-authored and never written by this script.

Requires: Pillow, and rsvg-convert (Debian/Ubuntu: librsvg2-bin).

Produces:
  Windows/res/usbkvm-app.ico        full-colour, shown in Explorer and Alt-Tab
  Windows/res/usbkvm-dark.ico       black silhouette, for light taskbars
  Windows/res/usbkvm-light.ico      white silhouette, for dark taskbars
  Windows/res/usbkvm-dark-off.ico   error variant, light taskbars
  Windows/res/usbkvm-light-off.ico  error variant, dark taskbars
  macOS/…/AppIcon.appiconset/Icon-*.png   the macOS app icon, all sizes
"""

import io
import os
import re
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "macOS", "USB KVM", "Assets.xcassets")
APPICON_DIR = os.path.join(ASSETS, "AppIcon.appiconset")

APP_SVG = os.path.join(ROOT, "assets", "icon.svg")

GNOME_ICONS = os.path.join(ROOT, "Linux", "gnome-extension", "icons")
SVG_STATUS = os.path.join(GNOME_ICONS, "usbkvm-symbolic.svg")
SVG_ERROR = os.path.join(GNOME_ICONS, "usbkvm-error-symbolic.svg")

WINDOWS_RES = os.path.join(ROOT, "Windows", "res")

# Sizes Windows picks between for the tray, Alt-Tab and the shell.
ICO_SIZES = [16, 20, 24, 32, 48, 64, 128, 256]

# Pixel sizes the macOS AppIcon.appiconset references (1x and 2x of 16/32/128/
# 256/512). Kept in sync with its Contents.json.
MACOS_APPICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]

BLACK = "#000000"
WHITE = "#ffffff"


def render_svg(svg_path, size, colour=None):
    """Renders one SVG at one size.

    When `colour` is given, it is injected as the CSS `color` on the root so that
    `currentColor` symbolic icons resolve to it — librsvg leaves currentColor
    black otherwise. Full-colour icons pass colour=None and render as authored.
    """
    svg = open(svg_path, encoding="utf-8").read()

    if colour is not None:
        svg, count = re.subn(r"<svg\b", f'<svg style="color:{colour}"', svg, count=1)
        if not count:
            raise RuntimeError(f"{svg_path}: no <svg> element found")

    with tempfile.NamedTemporaryFile("w", suffix=".svg", encoding="utf-8") as handle:
        handle.write(svg)
        handle.flush()

        result = subprocess.run(
            ["rsvg-convert", "-w", str(size), "-h", str(size), handle.name],
            capture_output=True, check=True)

    return Image.open(io.BytesIO(result.stdout)).convert("RGBA")


def write_ico(frames, path):
    """Writes a multi-resolution .ico from a {size: Image} mapping.

    Pillow drops any size larger than the image it is handed, so the largest
    frame is the base and the rest ride along via append_images -- which does
    preserve each frame as given rather than resampling the base.
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)

    ordered = sorted(frames)
    base = frames[ordered[-1]]
    rest = [frames[size] for size in ordered[:-1]]

    base.save(path, format="ICO",
              sizes=[(s, s) for s in ordered],
              append_images=rest)

    print(f"wrote {os.path.relpath(path, ROOT)} ({len(ordered)} sizes)")


def write_tray_ico(svg_path, colour, out_name):
    frames = {size: render_svg(svg_path, size, colour) for size in ICO_SIZES}
    write_ico(frames, os.path.join(WINDOWS_RES, out_name))


def write_app_ico():
    """Full-colour Windows app icon, each size rendered natively from the SVG."""
    frames = {size: render_svg(APP_SVG, size) for size in ICO_SIZES}
    write_ico(frames, os.path.join(WINDOWS_RES, "usbkvm-app.ico"))


def write_macos_appicon():
    """Renders every PNG the macOS AppIcon.appiconset references from the SVG."""
    for size in MACOS_APPICON_SIZES:
        image = render_svg(APP_SVG, size)
        out = os.path.join(APPICON_DIR, f"Icon-{size}.png")
        image.save(out, format="PNG")
    print(f"wrote {len(MACOS_APPICON_SIZES)} macOS app-icon PNGs")


def main():
    if not shutil.which("rsvg-convert"):
        print("error: rsvg-convert not found (apt install librsvg2-bin)",
              file=sys.stderr)
        return 1

    for required in (APP_SVG, SVG_STATUS, SVG_ERROR):
        if not os.path.exists(required):
            print(f"error: missing {required}", file=sys.stderr)
            return 1

    # A light taskbar needs the dark silhouette, and vice versa.
    write_tray_ico(SVG_STATUS, BLACK, "usbkvm-dark.ico")
    write_tray_ico(SVG_STATUS, WHITE, "usbkvm-light.ico")
    write_tray_ico(SVG_ERROR, BLACK, "usbkvm-dark-off.ico")
    write_tray_ico(SVG_ERROR, WHITE, "usbkvm-light-off.ico")

    write_app_ico()
    write_macos_appicon()

    return 0


if __name__ == "__main__":
    sys.exit(main())

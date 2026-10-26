#!/usr/bin/env python3
"""Apply the Noctalia palette to every Obsidian vault.

Noctalia runs this script as the post_hook of the `obsidian` user template in
~/.config/noctalia/user-templates.toml. The template renders the palette roles
to ~/.cache/noctalia/obsidian-palette.json. This script:

1. Builds a CSS snippet from the palette. Each text color is pushed away from
   its background until it meets a WCAG contrast minimum (see MIN_*), so a
   palette with dim roles still gives readable text.
2. Finds every vault: the vault list in obsidian.json (Flatpak and native),
   plus a scan of $HOME. The scan follows a symlinked .obsidian directory.
3. Writes .obsidian/snippets/noctalia.css into each vault, enables the
   snippet, clears any community theme, and sets the base theme to the
   Noctalia mode (dark -> "obsidian", light -> "moonstone").

Obsidian reloads a changed snippet file at once. A change to appearance.json
takes effect when the vault opens again.

Usage: obsidian-theme-apply.py <palette.json> [--check]
  --check  print the contrast of each text color and write nothing.
"""

import colorsys
import json
import os
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
SNIPPET = "noctalia"

# WCAG 2 contrast minimums against the worst background each color sits on.
MIN_NORMAL = 7.0  # body text (AAA)
MIN_MUTED = 4.5  # secondary text, icons, tabs (AA)
MIN_FAINT = 3.2  # placeholders, line numbers, collapsed icons
MIN_ACCENT = 4.5  # links, headings, tags, code tokens
MIN_BORDER = 1.6  # dividers and borders

OBSIDIAN_JSON = [
    HOME / ".var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json",
    HOME / ".config/obsidian/obsidian.json",
]


# ---- color math -------------------------------------------------------------


def rgb(hex_):
    h = hex_.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def hexc(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)


def lum(hex_):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = (ch(v) for v in rgb(hex_))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def mix(a, b, t):
    """Mix t of b into a."""
    return hexc([x + (y - x) * t for x, y in zip(rgb(a), rgb(b))])


def ensure(fg, bgs, minimum):
    """Move fg toward white (dark bg) or black (light bg) until it meets
    `minimum` against every color in bgs. The hue stays the same."""
    bgs = [bgs] if isinstance(bgs, str) else bgs
    target = "#ffffff" if lum(bgs[0]) < 0.18 else "#000000"
    out = fg
    for step in range(0, 101, 2):
        out = mix(fg, target, step / 100)
        if min(contrast(out, b) for b in bgs) >= minimum:
            break
    return out


def rgba(hex_, alpha):
    return "rgba(%d, %d, %d, %s)" % (*rgb(hex_), alpha)


def rgb_csv(hex_):
    return "%d, %d, %d" % rgb(hex_)


def hsl_vars(hex_):
    r, g, b = (v / 255 for v in rgb(hex_))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return round(h * 360), round(s * 100), round(l * 100)


# ---- CSS --------------------------------------------------------------------


def build(p, term, dark):
    """Return (css_variables, contrast_report) for one mode."""
    bg = p["surface"]
    bg_alt = p["surface_container_low"]
    bg2 = p["surface_container"]
    bg2_alt = p["surface_container_high"]
    bg_hi = p["surface_container_highest"]
    # Text must read on every layer it can sit on.
    text_bgs = [bg, bg_alt, bg2, bg2_alt]

    normal = ensure(p["on_surface"], text_bgs, MIN_NORMAL)
    muted = ensure(p["on_surface_variant"], text_bgs, MIN_MUTED)
    faint = ensure(p["outline"], text_bgs, MIN_FAINT)
    accent = ensure(p["primary"], text_bgs, MIN_ACCENT)
    secondary = ensure(p["secondary"], text_bgs, MIN_ACCENT)
    tertiary = ensure(p["tertiary"], text_bgs, MIN_ACCENT)
    error = ensure(p["error"], text_bgs, MIN_ACCENT)
    border = ensure(p["outline_variant"], [bg, bg2], MIN_BORDER)
    border_hi = ensure(p["outline"], [bg, bg2], MIN_BORDER + 0.6)
    code_bg = bg2 if dark else bg_alt
    code_normal = ensure(normal, code_bg, MIN_NORMAL)

    # Button text on the accent fill: keep on_primary only if it reads.
    on_accent = p["on_primary"]
    if contrast(on_accent, p["primary"]) < MIN_MUTED:
        on_accent = max(("#000000", "#ffffff"), key=lambda c: contrast(c, p["primary"]))
    accent_fill = p["primary"]

    named = {k: ensure(v, text_bgs, MIN_ACCENT) for k, v in term.items()}
    named["orange"] = ensure(mix(term["red"], term["yellow"], 0.5), text_bgs, MIN_ACCENT)
    named["purple"] = named["magenta"]
    named["pink"] = ensure(mix(term["magenta"], term["red"], 0.4), text_bgs, MIN_ACCENT)

    ah, as_, al = hsl_vars(accent_fill)
    v = {
        # Base scale. Obsidian derives most UI colors from it.
        "--color-base-00": bg,
        "--color-base-05": bg_alt,
        "--color-base-10": bg_alt,
        "--color-base-20": bg2,
        "--color-base-25": bg2_alt,
        "--color-base-30": border,
        "--color-base-35": border_hi,
        "--color-base-40": faint,
        "--color-base-50": faint,
        "--color-base-60": muted,
        "--color-base-70": muted,
        "--color-base-100": normal,
        # Accent. Obsidian computes hover and tint shades from these.
        "--accent-h": str(ah),
        "--accent-s": f"{as_}%",
        "--accent-l": f"{al}%",
        "--color-accent": accent_fill,
        "--color-accent-1": mix(accent_fill, "#ffffff" if dark else "#000000", 0.1),
        "--color-accent-2": mix(accent_fill, "#ffffff" if dark else "#000000", 0.2),
        # Backgrounds
        "--background-primary": bg,
        "--background-primary-alt": bg_alt,
        "--background-secondary": bg2,
        "--background-secondary-alt": bg2_alt,
        "--background-modifier-border": border,
        "--background-modifier-border-hover": border_hi,
        "--background-modifier-border-focus": accent,
        "--background-modifier-hover": rgba(normal, 0.075),
        "--background-modifier-active-hover": rgba(accent_fill, 0.18),
        "--background-modifier-form-field": p["surface_container_lowest"] if dark else bg,
        "--background-modifier-box-shadow": rgba(p["shadow"], 0.3),
        "--background-modifier-cover": rgba(p["shadow"], 0.6),
        "--background-modifier-error": rgba(error, 0.15),
        "--background-modifier-error-hover": rgba(error, 0.25),
        "--background-modifier-error-rgb": rgb_csv(error),
        "--background-modifier-success": rgba(named["green"], 0.15),
        # Text
        "--text-normal": normal,
        "--text-muted": muted,
        "--text-faint": faint,
        "--text-accent": accent,
        "--text-accent-hover": ensure(mix(accent, normal, 0.25), text_bgs, MIN_ACCENT),
        "--text-on-accent": on_accent,
        "--text-on-accent-inverted": accent_fill,
        "--text-error": error,
        "--text-success": named["green"],
        "--text-warning": named["orange"],
        "--text-selection": rgba(accent_fill, 0.28),
        "--text-highlight-bg": rgba(named["yellow"], 0.3),
        "--text-highlight-bg-active": rgba(named["orange"], 0.4),
        "--caret-color": normal,
        # Interactive
        "--interactive-normal": bg2,
        "--interactive-hover": bg2_alt,
        "--interactive-accent": accent_fill,
        "--interactive-accent-hover": mix(accent_fill, normal, 0.15),
        "--interactive-accent-rgb": rgb_csv(accent_fill),
        # Headings, emphasis, links
        "--h1-color": accent,
        "--h2-color": secondary,
        "--h3-color": tertiary,
        "--h4-color": named["blue"],
        "--h5-color": named["cyan"],
        "--h6-color": muted,
        "--inline-title-color": normal,
        "--bold-color": normal,
        "--italic-color": normal,
        "--link-color": accent,
        "--link-color-hover": ensure(mix(accent, normal, 0.25), text_bgs, MIN_ACCENT),
        "--link-external-color": tertiary,
        "--link-external-color-hover": ensure(mix(tertiary, normal, 0.25), text_bgs, MIN_ACCENT),
        "--link-unresolved-color": error,
        "--link-unresolved-opacity": "0.85",
        "--link-unresolved-decoration-color": rgba(error, 0.5),
        "--tag-color": secondary,
        "--tag-color-hover": normal,
        "--tag-background": rgba(secondary, 0.14),
        "--tag-background-hover": rgba(secondary, 0.24),
        "--tag-border-color": rgba(secondary, 0.3),
        "--blockquote-border-color": accent,
        "--list-marker-color": muted,
        "--list-marker-color-hover": normal,
        "--checkbox-color": accent_fill,
        "--checkbox-color-hover": mix(accent_fill, normal, 0.15),
        "--checkbox-border-color": muted,
        "--checkbox-marker-color": on_accent,
        "--hr-color": border_hi,
        # Code blocks and syntax
        "--code-background": code_bg,
        "--code-normal": code_normal,
        "--code-comment": ensure(faint, code_bg, MIN_FAINT + 0.5),
        "--code-function": ensure(named["yellow"], code_bg, MIN_ACCENT),
        "--code-important": ensure(named["orange"], code_bg, MIN_ACCENT),
        "--code-keyword": ensure(named["magenta"], code_bg, MIN_ACCENT),
        "--code-operator": ensure(named["red"], code_bg, MIN_ACCENT),
        "--code-property": ensure(named["cyan"], code_bg, MIN_ACCENT),
        "--code-punctuation": ensure(muted, code_bg, MIN_MUTED),
        "--code-string": ensure(named["green"], code_bg, MIN_ACCENT),
        "--code-tag": ensure(named["red"], code_bg, MIN_ACCENT),
        "--code-value": ensure(named["blue"], code_bg, MIN_ACCENT),
        # Navigation, tabs, chrome
        "--nav-item-color": muted,
        "--nav-item-color-hover": normal,
        "--nav-item-color-active": normal,
        "--nav-item-color-selected": normal,
        "--nav-item-background-hover": rgba(normal, 0.075),
        "--nav-item-background-active": rgba(accent_fill, 0.22),
        "--nav-item-background-selected": rgba(accent_fill, 0.3),
        "--nav-collapse-icon-color": muted,
        "--nav-collapse-icon-color-collapsed": faint,
        "--tab-text-color": muted,
        "--tab-text-color-focused": normal,
        "--tab-text-color-focused-active": normal,
        "--tab-text-color-focused-active-current": normal,
        "--tab-background-active": bg,
        "--tab-divider-color": border,
        "--tab-outline-color": border,
        "--titlebar-background": bg2,
        "--titlebar-background-focused": bg2_alt,
        "--titlebar-text-color": muted,
        "--titlebar-text-color-focused": normal,
        "--status-bar-background": bg2,
        "--status-bar-border-color": border,
        "--status-bar-text-color": muted,
        "--ribbon-background": bg2,
        "--ribbon-background-collapsed": bg,
        "--vault-name-color": normal,
        "--icon-color": muted,
        "--icon-color-hover": normal,
        "--icon-color-active": accent,
        "--icon-color-focused": normal,
        "--divider-color": border,
        "--divider-color-hover": accent,
        "--modal-background": bg,
        "--modal-border-color": border_hi,
        "--prompt-border-color": border_hi,
        "--scrollbar-bg": "transparent",
        "--scrollbar-thumb-bg": rgba(muted, 0.25),
        "--scrollbar-active-thumb-bg": rgba(muted, 0.45),
        "--indentation-guide-color": rgba(muted, 0.2),
        "--indentation-guide-color-active": rgba(muted, 0.45),
        "--table-border-color": border,
        "--table-header-background": bg2,
        "--table-row-alt-background": bg_alt,
        "--embed-border-left": f"2px solid {accent}",
        # Graph
        "--graph-line": border_hi,
        "--graph-node": muted,
        "--graph-node-unresolved": faint,
        "--graph-node-focused": accent,
        "--graph-node-tag": secondary,
        "--graph-node-attachment": tertiary,
        "--graph-text": normal,
    }
    # Named colors drive callouts, highlights and plugin colors.
    for k in ("red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"):
        v[f"--color-{k}"] = named[k]
        v[f"--color-{k}-rgb"] = rgb_csv(named[k])

    worst = min(bg, bg_alt, bg2, bg2_alt, key=lambda c: abs(lum(c) - lum(normal)))
    report = {
        "text-normal": contrast(normal, worst),
        "text-muted": contrast(muted, worst),
        "text-faint": contrast(faint, worst),
        "text-accent": contrast(accent, worst),
        "text-on-accent": contrast(on_accent, accent_fill),
        "code-normal": contrast(code_normal, code_bg),
    }
    return v, report


def css(palette):
    term = palette["terminal"]
    blocks = []
    reports = {}
    for mode, selector in (("dark", ".theme-dark"), ("light", ".theme-light")):
        v, reports[mode] = build(palette[mode], term, mode == "dark")
        body = "\n".join(f"  {k}: {val};" for k, val in v.items())
        blocks.append(f"body{selector} {{\n{body}\n}}")
    header = (
        "/* Generated by ~/.config/noctalia/scripts/obsidian-theme-apply.py from the\n"
        " * Noctalia palette. Do not edit: the next palette change overwrites it. */\n"
    )
    return header + "\n\n".join(blocks) + "\n", reports


# ---- vaults -----------------------------------------------------------------


def vaults():
    found = {}
    for f in OBSIDIAN_JSON:
        try:
            for entry in json.loads(f.read_text()).get("vaults", {}).values():
                d = Path(entry["path"]) / ".obsidian"
                if d.is_dir():
                    found.setdefault(d.resolve(), d)
        except (OSError, ValueError, KeyError):
            pass
    # A vault that Obsidian has not opened on this machine is not in
    # obsidian.json. `-L` follows a symlinked .obsidian (find -type d skips it).
    scan = subprocess.run(
        ["find", "-L", str(HOME), "-maxdepth", "5", "-name", ".obsidian", "-type", "d",
         "-not", "-path", "*/.local/share/Trash/*", "-not", "-path", "*/node_modules/*"],
        capture_output=True, text=True,
    )
    for line in scan.stdout.splitlines():
        d = Path(line)
        found.setdefault(d.resolve(), d)
    return sorted(found.values())


def update_appearance(obsidian_dir, mode):
    f = obsidian_dir / "appearance.json"
    try:
        data = json.loads(f.read_text())
    except (OSError, ValueError):
        data = {}
    want = dict(data)
    snippets = want.get("enabledCssSnippets", [])
    if SNIPPET not in snippets:
        want["enabledCssSnippets"] = snippets + [SNIPPET]
    # A community theme sets its own colors and fights the snippet.
    want["cssTheme"] = ""
    want["theme"] = "obsidian" if mode == "dark" else "moonstone"
    if want != data:
        f.write_text(json.dumps(want, indent=2) + "\n")
        return True
    return False


def write_if_changed(path, text):
    try:
        if path.read_text() == text:
            return False
    except OSError:
        pass
    tmp = path.with_suffix(".css.tmp")
    tmp.write_text(text)
    os.replace(tmp, path)
    return True


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        sys.exit(__doc__)
    palette = json.loads(Path(os.path.expanduser(args[0])).read_text())
    mode = "light" if palette.get("mode", "dark").strip() == "light" else "dark"
    text, reports = css(palette)

    if "--check" in sys.argv:
        for m, r in reports.items():
            print(m, " ".join(f"{k}={v:.2f}" for k, v in r.items()))
        return

    for d in vaults():
        snip_dir = d / "snippets"
        snip_dir.mkdir(exist_ok=True)
        css_changed = write_if_changed(snip_dir / f"{SNIPPET}.css", text)
        app_changed = update_appearance(d, mode)
        print(f"{d.parent}: snippet {'updated' if css_changed else 'unchanged'}, "
              f"appearance.json {'updated' if app_changed else 'unchanged'}")


if __name__ == "__main__":
    main()

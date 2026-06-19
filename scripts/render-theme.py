#!/usr/bin/env python3
"""Render a Noctalia color template against a fixed palette JSON.

Reuses the SAME templates Noctalia uses for the wallpaper theme
(noctalia/.config/noctalia/templates/), but substitutes a predefined palette
instead of wallpaper-extracted colors. Used to generate the server theme without
running Noctalia/matugen — see scripts/deploy-server-theme.sh.

Palette JSON: { "<role>": "#rrggbb", ... }  (keys starting with "_" are ignored)
Templates reference {{colors.<role>.default.<red|green|blue|hex>}}.

Usage: render-theme.py <palette.json> <template-file>   # rendered output -> stdout
"""
import json
import re
import sys

TOKEN = re.compile(r"\{\{colors\.([a-z_]+)\.default\.(red|green|blue|hex_stripped|hex)\}\}")


def components(hexv):
    h = hexv.lstrip("#").lower()
    return {
        "red": int(h[0:2], 16),
        "green": int(h[2:4], 16),
        "blue": int(h[4:6], 16),
        "hex": "#" + h,
        "hex_stripped": h,
    }


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: render-theme.py <palette.json> <template-file>")
    palette = {k: v for k, v in json.load(open(sys.argv[1])).items() if not k.startswith("_")}
    text = open(sys.argv[2]).read()

    missing = set()

    def sub(m):
        role, comp = m.group(1), m.group(2)
        if role not in palette:
            missing.add(role)
            return m.group(0)
        return str(components(palette[role])[comp])

    out = TOKEN.sub(sub, text)
    if missing:
        sys.exit("ERROR: palette is missing roles: " + ", ".join(sorted(missing)))
    sys.stdout.write(out)


if __name__ == "__main__":
    main()

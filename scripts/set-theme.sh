#!/usr/bin/env python3
"""
Switch the visual theme across nvim and zellij in one shot.

Usage:
    scripts/set-theme.sh tokyonight-storm
    scripts/set-theme.sh dracula

After running, restart zellij for the change to take effect.
Nvim picks up the change immediately on next launch (no restart needed).
"""
import sys
import re
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent.parent
ZELLIJ_CONFIG = DOTFILES / "zellij/.config/zellij/config.kdl"
NVIM_COLORSCHEME = DOTFILES / "nvim/.config/nvim/lua/plugins/colorscheme.lua"

# zjstatus color palettes — one block per theme
PALETTES = {
    "tokyonight-storm": """\
        color_rosewater "#c0caf5"
        color_flamingo "#f7768e"
        color_pink "#bb9af7"
        color_mauve "#bb9af7"
        color_red "#f7768e"
        color_maroon "#db4b4b"
        color_peach "#ff9e64"
        color_yellow "#e0af68"
        color_green "#9ece6a"
        color_teal "#73daca"
        color_sky "#7dcfff"
        color_sapphire "#2ac3de"
        color_blue "#7aa2f7"
        color_lavender "#89ddff"
        color_text "#c0caf5"
        color_subtext1 "#a9b1d6"
        color_subtext0 "#9aa5ce"
        color_overlay2 "#7a8597"
        color_overlay1 "#737aa2"
        color_overlay0 "#565f89"
        color_surface2 "#414868"
        color_surface1 "#3b4261"
        color_surface0 "#292e42"
        color_base "#24283b"
        color_mantle "#1f2335"
        color_crust "#1a1b26\"""",

    "dracula": """\
        color_rosewater "#f8f8f2"
        color_flamingo "#ff79c6"
        color_pink "#ff79c6"
        color_mauve "#bd93f9"
        color_red "#ff5555"
        color_maroon "#ff5555"
        color_peach "#ffb86c"
        color_yellow "#f1fa8c"
        color_green "#ff79c6"
        color_teal "#ffb86c"
        color_sky "#ffb86c"
        color_sapphire "#ff5555"
        color_blue "#ffb86c"
        color_lavender "#bd93f9"
        color_text "#f8f8f2"
        color_subtext1 "#f8f8f2"
        color_subtext0 "#6272a4"
        color_overlay2 "#6272a4"
        color_overlay1 "#6272a4"
        color_overlay0 "#44475a"
        color_surface2 "#44475a"
        color_surface1 "#383a59"
        color_surface0 "#44475a"
        color_base "#282a36"
        color_mantle "#21222c"
        color_crust "#21222c\"""",

    "catppuccin-macchiato-custom": """\
        color_rosewater "#f4dbd6"
        color_flamingo "#f0c6c6"
        color_pink "#f5bde6"
        color_mauve "#c6a0f6"
        color_red "#ed8796"
        color_maroon "#ee99a0"
        color_peach "#f5a97f"
        color_yellow "#eed49f"
        color_green "#a6da95"
        color_teal "#8bd5ca"
        color_sky "#91d7e3"
        color_sapphire "#7dc4e4"
        color_blue "#8aadf4"
        color_lavender "#b7bdf8"
        color_text "#cad3f5"
        color_subtext1 "#b8c0e0"
        color_subtext0 "#a5adcb"
        color_overlay2 "#939ab7"
        color_overlay1 "#8087a2"
        color_overlay0 "#6e738d"
        color_surface2 "#5b6078"
        color_surface1 "#494d64"
        color_surface0 "#363a4f"
        color_base "#24273a"
        color_mantle "#1e2030"
        color_crust "#181926\"""",
}

# Map theme names to nvim colorscheme names
NVIM_THEME = {
    "tokyonight-storm": "tokyonight",
    "dracula": "dracula",
    "catppuccin-macchiato-custom": "catppuccin-macchiato",
}

AVAILABLE = list(PALETTES.keys())


def usage():
    print(f"Usage: {sys.argv[0]} <theme>")
    print(f"Available themes: {', '.join(AVAILABLE)}")
    sys.exit(1)


def update_zellij(theme: str):
    text = ZELLIJ_CONFIG.read_text()

    # Replace the theme line
    text = re.sub(r'^theme ".*"', f'theme "{theme}"', text, flags=re.MULTILINE)

    # Replace the zjstatus palette block (between markers)
    palette = PALETTES[theme]
    new_header = f"    // ── THEME PALETTE: {theme} ── (run scripts/set-theme.sh to swap)"
    new_block = f"{new_header}\n{palette}\n    // ── END THEME PALETTE ─────────────────────────────────────────────────────"
    text = re.sub(
        r"    // ── THEME PALETTE: .*?// ── END THEME PALETTE ─+",
        new_block,
        text,
        flags=re.DOTALL,
    )

    ZELLIJ_CONFIG.write_text(text)
    print(f"  zellij: theme set to '{theme}'")


def update_nvim(theme: str):
    nvim_name = NVIM_THEME.get(theme)
    if nvim_name is None:
        print(f"  nvim: no mapping for '{theme}', skipping")
        return

    text = NVIM_COLORSCHEME.read_text()
    text = re.sub(
        r'(colorscheme = )"[^"]*"',
        f'\\1"{nvim_name}"',
        text,
    )
    NVIM_COLORSCHEME.write_text(text)
    print(f"  nvim: colorscheme set to '{nvim_name}'")


def main():
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        usage()

    theme = sys.argv[1]
    if theme not in PALETTES:
        print(f"Unknown theme: {theme}")
        usage()

    print(f"Setting theme: {theme}")
    update_zellij(theme)
    update_nvim(theme)
    print("Done. Restart zellij to apply the zellij changes.")


if __name__ == "__main__":
    main()

# zsh colours, rendered by Noctalia from the active palette.
#
# Source: ~/.config/noctalia/templates/zsh-theme.zsh
# Output: ~/.config/zsh/noctalia-theme.zsh   (generated, gitignored, never edit)
# Wiring: user-templates.toml -> [theme.templates.user.zsh]
# Read by: home/.zshrc, before oh-my-zsh loads its plugins.

# zsh-autosuggestions greys out the suggested command after the cursor. Its
# default is fg=8, and Noctalia maps kitty colour 8 to a near-background dark
# blue (1.4:1 against the surface), so the suggestion is unreadable.
# on_surface_variant is the palette's dim-text role, the same colour nvim gets
# as base04 in templates/nvim-theme.lua. It sits near 5:1 against the surface.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg={{colors.on_surface_variant.default.hex}}'

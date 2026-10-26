# theme: catppuccin

Saved 2026-08-25. Describe the intent here — the key list won't.

- **Feel:**
- **Palette:** theme.builtin = "Catppuccin"

## Wallpaper source

`wallpaper-prism.svg` is a vector rebuild of
`~/Pictures/Wallpapers/3vpd1ov7brib1.png` (Dark Side of the Moon prism). The
geometry is measured from the original PNG. The original PNG had JPEG
artifacts. The original is kept as `3vpd1ov7brib1.orig.png`.

To render the PNG again (any resolution):

    magick -background none -density 96 wallpaper-prism.svg -alpha off \
      ~/Pictures/Wallpapers/3vpd1ov7brib1.png

For a larger PNG, increase `-density` (192 gives 7680x4320).

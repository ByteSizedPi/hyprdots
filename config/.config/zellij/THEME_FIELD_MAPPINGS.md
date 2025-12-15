# Zellij Theme Field Mappings

This document details the exact mapping of theme color fields to UI elements in Zellij, discovered through testing.

## Ribbon (Tab Bar) Components

### `text_unselected`
- **`background`**: Controls the **RIBBON BACKGROUND** (the overall tab bar background)
- **`emphasis_2`**: Controls the **MODE INDICATOR TEXT in NORMAL mode**
- Other fields: Used for general UI text elements

### `text_selected`
- **`emphasis_2`**: Controls the **MODE INDICATOR TEXT in OTHER MODES** (PANE, TAB, SESSION, RESIZE, MOVE, etc.)
- Other fields: Used for selected text UI elements

### `ribbon_selected`
- **`base`**: Active tab/mode indicator **TEXT COLOR**
- **`background`**: Active tab/mode indicator **BACKGROUND COLOR**
- Note: This component controls BOTH the active tab AND the mode indicator together (cannot be styled separately)

### `ribbon_unselected`
- **`base`**: Text color for **ODD-INDEXED INACTIVE TABS** (tabs 1, 3, 5, 7...)
- **`background`**: Background color for **ODD-INDEXED INACTIVE TABS**
- **`emphasis_1`**: Background color for **EVEN-INDEXED INACTIVE TABS** (tabs 2, 4, 6, 8...)
- **`emphasis_0`**, **`emphasis_2`**, **`emphasis_3`**: Other alternating/emphasis colors

## Current Configuration Summary

### Ribbon Background
- Color: Crust (#181926 / 24 25 38)
- Location: `text_unselected.background`

### Mode Indicator
- **NORMAL mode**: Blue (#8aadf4 / 138 173 244)
  - Location: `text_unselected.emphasis_2`
- **Other modes**: Red (#ed8796 / 237 135 150)
  - Location: `text_selected.emphasis_2`

### Active Tab
- Background: Blue (#8aadf4 / 138 173 244)
- Text: Crust (#181926 / 24 25 38)
- Location: `ribbon_selected.background` and `ribbon_selected.base`

### Inactive Tabs
- **Odd tabs (1, 3, 5...)**:
  - Text: Light lavender (202 211 245)
  - Background: Crust (#181926 / 24 25 38)
  - Location: `ribbon_unselected.base` and `ribbon_unselected.background`

- **Even tabs (2, 4, 6...)**:
  - Text: Light lavender (same as odd)
  - Background: Mantle (#313244 / 49 50 68) - slightly lighter than crust
  - Location: `ribbon_unselected.emphasis_1`

## Catppuccin Macchiato Color Reference

- **Crust**: #181926 (24 25 38) - Darkest background
- **Mantle**: #313244 (49 50 68) - Slightly lighter than crust
- **Base**: #24273a (30 32 48) - Base background
- **Surface0**: #363a4f (54 58 79)
- **Surface1**: #5b6078 (91 96 120)
- **Text**: #cad3f5 (202 211 245) - Light lavender
- **Subtext0**: #a5adcb (165 173 203)
- **Blue**: #8aadf4 (138 173 244)
- **Red**: #ed8796 (237 135 150)

## Testing Method

To discover field mappings:
1. Set all `emphasis_0` through `emphasis_3` fields to bright, distinct colors (pure red, green, blue, yellow, etc.)
2. Reload Zellij and observe which UI elements changed to which colors
3. Map the colors back to their field names
4. Restore proper theme colors once mapping is confirmed

## Limitations

- The `ribbon_selected` component controls both the mode indicator and active tab together
- There is no way to style the mode indicator separately from the active tab using standard theme fields
- Custom styling would require modifying the status bar plugin itself

-- Laptop built-in. Always at origin.
hl.monitor({
	output   = "BOE 0x0B8E",
	mode     = "1920x1080",
	position = "0x0",
	scale    = 1,
})

-- AOC external. Ignored by Hyprland when not connected, so no kanshi needed.
hl.monitor({
	output   = "AOC 24G2W1G3-",
	mode     = "1920x1080@144",
	position = "1920x0",
	scale    = 1,
})

-- Catch-all for any other/unknown outputs
hl.monitor({
	output   = "",
	mode     = "preferred",
	position = "auto",
	scale    = 1,
})

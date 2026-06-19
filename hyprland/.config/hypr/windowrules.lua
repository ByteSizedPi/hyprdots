hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.layer_rule({
	name = "noctalia-bar-blur",
	match = { namespace = "^noctalia-bar.*" },
	blur = true,
	blur_popups = true,
	xray = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-panel-blur",
	match = { namespace = "^noctalia-panel" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-screen-corner-blur",
	match = { namespace = "^noctalia-screen-corner" },
	blur = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-notification-blur",
	match = { namespace = "^noctalia-notification$" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-attached-panel-blur",
	match = { namespace = "^noctalia-attached-panel$" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-osd-blur",
	match = { namespace = "^noctalia-osd$" },
	blur = true,
	ignore_alpha = 0.5,
})

-- Semi-transparent Noctalia Settings window
hl.window_rule({
	name = "noctalia-settings-opacity",
	match = { class = "^dev\\.noctalia\\.Noctalia\\.Settings$" },
	opacity = "0.8 override 0.8 override",
})

-- Launch zellij in the special:zellij scratchpad when first opened
local _t = os.getenv("TERMINAL")
local _terminal = (_t ~= nil and _t ~= "" and _t) or "xdg-terminal-exec"

hl.workspace_rule({
	workspace = "special:zellij",
	on_created_empty = _terminal .. " zellij attach main --create",
})

hl.workspace_rule({
	workspace = "special:jjserver",
	on_created_empty = _terminal .. " ssh -t jjserver@100.68.211.32 zellij attach jjserver --create",
})

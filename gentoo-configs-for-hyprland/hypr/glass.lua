-- Add to ~/.config/hypr/hyprland.lua  (Hyprland 0.55+ Lua config)
-- Adjust QS if you installed the shell as the default config (then just "qs").
--local QS = "qs -c glass"

-- autostart (stop waybar / dunst / mako first, they clash with the bar and notification server)
--hl.on("hyprland.start", function()
-- hl.exec_cmd(QS)
--end)

-- frosted glass: blur everything the shell draws, but skip nearly-transparent pixels
-- (shadows, the click-catcher) so only the glass bodies get blurred
hl.layer_rule({
	name = "qsglass-blur",
	match = { namespace = "^qsglass-.*$" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.25,
	no_anim = true, -- the shell animates itself
})
hl.layer_rule({
	name = "qsscrim-noanim",
	match = { namespace = "^qsscrim$" },
	no_anim = true,
})

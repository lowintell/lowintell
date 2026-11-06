-- Add to ~/.config/hypr/hyprland.lua  (Hyprland 0.55+ Lua config)
-- Adjust QS if you installed the shell as the default config (then just "qs").
local QS = "qs -c glass"

-- autostart (stop waybar / dunst / mako first, they clash with the bar and notification server)
hl.on("hyprland.start", function()
    hl.exec_cmd(QS)
end)

-- frosted glass: blur everything the shell draws, but skip nearly-transparent pixels
-- (shadows, the click-catcher) so only the glass bodies get blurred
hl.layer_rule({
    name = "qsglass-blur",
    match = { namespace = "^qsglass-.*$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.25,
    no_anim = true,   -- the shell animates itself
})
hl.layer_rule({
    name = "qsscrim-noanim",
    match = { namespace = "^qsscrim$" },
    no_anim = true,
})

-- keybinds (pick your own; these are examples)
local ipc = QS .. " ipc call shell "
hl.bind("SUPER + Space", hl.dsp.exec_cmd(ipc .. "toggle launcher"))
hl.bind("SUPER + A",     hl.dsp.exec_cmd(ipc .. "toggle quick"))
hl.bind("SUPER + N",     hl.dsp.exec_cmd(ipc .. "toggle notifs"))
hl.bind("SUPER + M",     hl.dsp.exec_cmd(ipc .. "toggle media"))
hl.bind("SUPER + W",     hl.dsp.exec_cmd(ipc .. "toggle weather"))
hl.bind("SUPER + I",     hl.dsp.exec_cmd(ipc .. "toggle system"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd(ipc .. "close"))

-- make sure blur is on in your decoration block, e.g.
-- hl.config({ decoration = { blur = { enabled = true, size = 6, passes = 3, vibrancy = 0.17, noise = 0.02 } } })

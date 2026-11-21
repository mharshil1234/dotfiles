hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Super+Shift+1..9: move window to workspace and follow it
for i = 1, 9 do
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({workspace = i, follow = true}),
        i == 1 and {description = "Move window to workspace 1-9 (and follow)"} or nil) -- one cheatsheet line for all nine
end

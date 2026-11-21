-- Custom startup commands (safe from dots-hyprland updates)
hl.on("hyprland.start", function ()
    -- Safety net for autologin: if the Quickshell lock screen didn't start, lock with hyprlock
    hl.exec_cmd("sleep 10 && (pgrep -x qs >/dev/null || hyprlock)")

    -- Startup apps
    hl.exec_cmd("sleep 2 && hyprctl dispatch workspace 1")
    hl.exec_cmd('sleep 2.5 && kitty --title kitty-fetch -e fish -C fastfetch')
    hl.exec_cmd("sleep 4 && command -v spotify-launcher >/dev/null && spotify-launcher") -- only if Spotify is installed
end)

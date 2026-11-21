-- Custom startup commands (safe from dots-hyprland updates)
hl.on("hyprland.start", function ()
    -- Safety net for autologin: if the Quickshell lock screen didn't start, lock with hyprlock
    hl.exec_cmd("sleep 10 && (pgrep -x qs >/dev/null || hyprlock)")

    -- Startup apps
    hl.exec_cmd("sleep 2 && hyprctl dispatch workspace 1")
    hl.exec_cmd("sleep 2.5 && kitty --title kitty-fetch -e sh -c 'fish -c fastfetch; exec fish'") -- fastfetch before the interactive fish starts: its first prompt erases images drawn during its startup
    hl.exec_cmd("~/.config/hypr/custom/scripts/spotify-after-unlock.sh") -- waits for the boot lock screen to be unlocked
end)

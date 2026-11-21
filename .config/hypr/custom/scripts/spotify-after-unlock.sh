#!/usr/bin/env bash
# Start Spotify at login, but only after the boot lock screen is unlocked.
# Opened behind the lock screen, its window stays blank until reopened.
command -v spotify-launcher >/dev/null || exit 0
marker="${XDG_RUNTIME_DIR:-/tmp}/ii-unlocked" # touched by the shell's lock screen (modules/ii/lock/Lock.qml) on unlock
rm -f "$marker"

if [[ "$(jq -r '.lock.launchOnStartup' ~/.config/illogical-impulse/config.json 2>/dev/null)" == true ]]; then
    sleep 3
    seen_hyprlock=0
    for _ in $(seq 3600); do # give up waiting after an hour
        [[ -e "$marker" ]] && break
        # Fallback lock (hyprlock, see execs.lua): unlocked once it has started and exited
        if pgrep -x hyprlock >/dev/null; then seen_hyprlock=1
        elif ((seen_hyprlock)); then break; fi
        sleep 1
    done
fi

sleep 1
pgrep -x spotify >/dev/null || exec spotify-launcher

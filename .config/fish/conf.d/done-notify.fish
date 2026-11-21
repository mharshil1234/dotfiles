# Desktop notification when a long command finishes in a terminal you're not looking at.
status is-interactive; or exit

set -g __done_min_seconds 15

function __done_preexec --on-event fish_preexec
    set -g __done_window (hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' 2>/dev/null)
end

function __done_postexec --on-event fish_postexec
    set -l exit_status $status
    test -n "$CMD_DURATION"; or return
    test (math "$CMD_DURATION / 1000") -ge $__done_min_seconds; or return
    set -l now (hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' 2>/dev/null)
    test "$now" = "$__done_window"; and return   # you're still looking at it

    set -l secs (math --scale=0 "$CMD_DURATION / 1000")
    set -l took (math --scale=0 "$secs / 60")m(math "$secs % 60")s
    test $secs -lt 60; and set took {$secs}s
    set -l cmd (string shorten -m 60 -- "$argv[1]")
    if test $exit_status -eq 0
        notify-send -a Terminal -i utilities-terminal "Done in $took" "$cmd"
    else
        notify-send -a Terminal -u critical -i dialog-error "Failed ($exit_status) after $took" "$cmd"
    end
end

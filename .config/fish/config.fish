# ── PATH (all shells-safe, no duplicates) ──
fish_add_path -g "$HOME/.local/bin" "$HOME/.opencode/bin"
test -f ~/google-cloud-sdk/path.fish.inc; and source ~/google-cloud-sdk/path.fish.inc

if status is-interactive
    set fish_greeting

    # Prompt: starship (from dots-hyprland), with transient prompt
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"; and type -q starship
        starship init fish | source
        enable_transience
    end

    # Terminal colors generated from the wallpaper
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Smarter cd: `z proj` jumps to ~/Projects, `zi` picks interactively
    type -q zoxide; and zoxide init fish | source

    # fzf: Ctrl+R history search, Ctrl+T file picker, Alt+C cd into dir
    if type -q fzf
        set -gx FZF_DEFAULT_OPTS "--height 40% --layout reverse --border rounded --color 16"
        type -q fd; and set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude .git"
        type -q fd; and set -gx FZF_CTRL_T_COMMAND "fd --type f --hidden --exclude .git"
        fzf --fish | source
    end

    # ── Aliases ──
    # kitty doesn't clear scrollback properly, so print the escape codes
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar clear
    alias claer clear
    alias pamcan pacman
    alias q 'qs -c ii'
    alias next-clean 'rm -rf .next'
    alias dots "git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

    if test "$TERM" != "linux"; and type -q eza
        alias ls 'eza --icons --group-directories-first'
        alias ll 'eza -l --icons --git --group-directories-first'
        alias la 'eza -la --icons --git --group-directories-first'
        alias tree 'eza --tree --icons'
    end
    if type -q bat
        set -gx BAT_THEME ansi   # follow the wallpaper terminal colors
        alias cat 'bat --paging=never --style=plain'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end

# Restart Wi-Fi when it gets stuck
function fixwifi
    sudo ip link set wlo1 down
    sudo ip link set wlo1 up
    nmcli device connect wlo1
end

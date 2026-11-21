function fixwifi
    sudo ip link set wlo1 down
    sudo ip link set wlo1 up
    nmcli device connect wlo1
end


# Added by Antigravity CLI installer
fish_add_path -g "$HOME/.local/bin"

# Dotfiles repo (see ~/.dotfiles)
alias dots "git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

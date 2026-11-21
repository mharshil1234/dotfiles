# dotfiles

Arch Linux + Hyprland, built on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) ("illogical-impulse", Quickshell shell), with my own changes on top.

This is a **bare git repo** whose work tree is `$HOME`. Files stay in their normal places and only the files listed below are tracked. Untracked files are hidden from `dots status`.

## What's in here

| Area | Files | Notes |
|---|---|---|
| Hyprland | `.config/hypr/` | My changes live in `custom/` (startup apps, `Super+Shift+1–9`, kitty-first terminal, cursor env, hyprlock fallback). The one exception is the gesture change in `hyprland/general.lua`, because Hyprland can't remove a default gesture from `custom/`. |
| Shell (Quickshell `ii`) | `.config/quickshell/` | Custom lock screen in `modules/ii/lock/LockSurface.qml`: centered clock, greeting, date, stats bar (weather, battery, layout, time locked), a Spotify-only media card, and power buttons bottom-right. |
| Shell settings | `.config/illogical-impulse/config.json` | Lock on startup is on, weather uses IP location (GPS off, because geoclue gets my location wrong). |
| Lock fallback | `.config/hypr/hyprlock.conf`, `hyprlock/` | Used only if Quickshell isn't running. |
| Terminal | `.config/kitty/`, `.config/fish/`, `.config/starship.toml`, `.config/fastfetch/` | fish is the interactive shell; bash stays the login shell. |
| Theme | `.config/gtk-3.0/`, `.config/gtk-4.0/`, `.gtkrc-2.0`, `.config/xsettingsd/`, `.config/kdeglobals`, `.config/kcminputrc`, `.config/qt6ct/`, `.icons/default/` | adw-gtk3 with wallpaper-generated (Material You) colors and the Bibata-Modern-Classic cursor everywhere. |
| Other | `.bashrc`, `.bash_profile`, `.profile`, `.zshrc`, `.gitconfig`, `.config/mimeapps.list`, `*-flags.conf` | |

## Fresh install

### 1. Base system and dots-hyprland
Install Arch, then install dots-hyprland using its own installer (it pulls in Hyprland, Quickshell and the rest):
```bash
git clone https://github.com/end-4/dots-hyprland ~/dots-hyprland
cd ~/dots-hyprland && ./setup install
```

### 2. Extra packages these configs use
```bash
sudo pacman -S --needed kitty fish starship fastfetch eza bat fd fzf zoxide \
  hyprlock hypridle adw-gtk-theme jq curl \
  pacman-contrib ufw reflector timeshift fwupd
```
The Bibata-Modern-Classic cursor comes with dots-hyprland (package `illogical-impulse-bibata-modern-classic-bin`).

### 3. Restore these dotfiles
```bash
git clone --bare https://github.com/mharshil1234/dotfiles.git ~/.dotfiles
alias dots='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dots config status.showUntrackedFiles no
dots checkout
```
If `checkout` fails because files already exist (the defaults dots-hyprland just installed), move them aside and try again:
```bash
mkdir -p ~/.dotfiles-conflicts
dots checkout 2>&1 | grep -E '^\s+\.' | awk '{print $1}' | \
  xargs -I{} sh -c 'mkdir -p ~/.dotfiles-conflicts/$(dirname {}) && mv ~/{} ~/.dotfiles-conflicts/{}'
dots checkout
```

### 4. System settings (not stored in this repo)
These live outside `$HOME`, so redo them by hand:
```bash
# Power: use power-profiles-daemon only
sudo systemctl disable --now tlp

# Package cache cleanup, firewall, mirrors
sudo systemctl enable --now paccache.timer
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo systemctl enable --now ufw && sudo ufw enable
sudo systemctl enable --now reflector.timer
```
- **Mirrors:** `/etc/xdg/reflector/reflector.conf` should contain:
  ```
  --save /etc/pacman.d/mirrorlist
  --country India,Singapore
  --protocol https
  --latest 10
  --sort rate
  ```
- **Auto-login to the lock screen:** run `kcmshell6 kcm_plasmalogin`, turn on automatic login, and pick session **Hyprland**. The shell then locks immediately at login, so the boot screen is the custom lock screen. If Quickshell fails to start, `custom/execs.lua` falls back to hyprlock after 10 seconds.
- **Snapshots:** run `sudo timeshift-launcher`, choose RSYNC on the root partition, exclude home folders, and schedule Daily (keep 5) and Weekly (keep 3).

### 5. Log out and back in
Then press `Super+L` to check the lock screen.

## Daily use

```bash
dots status                 # what changed
dots diff                   # see the changes
dots add -u                 # stage changes to tracked files
dots add <file>             # start tracking a new file
dots commit -m "message"
dots push
```

After updating dots-hyprland, run `dots status` and `dots diff`. If the update overwrote something of mine (most likely `hyprland/general.lua` or the lock screen QML), restore it with `dots checkout -- <file>`.

## Notes

- **Theme:** colors come from the wallpaper. Changing the wallpaper in the shell regenerates colors for the shell, GTK, Qt, kitty and Hyprland.
- **Login shell:** bash stays the login shell on purpose, because fish isn't POSIX and can break `~/.profile` loading at login. kitty is set to run fish.
- **Secrets:** none are stored here. The shell keeps API keys in the system keyring.

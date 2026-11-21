# dotfiles

My whole Arch Linux setup: Hyprland with the Quickshell "illogical-impulse" shell, my own lock screen, theme, terminal, apps and system tweaks.

It's based on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), but **this repo is self-contained**. end-4's package recipes and shell code are included (GPL-3.0, credited in `.bootstrap/pkgbuilds/LICENSE-dots-hyprland`), so you don't need to clone end-4's repo.

## Install on a fresh Arch Linux

Start from a minimal Arch install (with `sudo`, networking and your normal user), then log in as that user and run:

```bash
sudo pacman -S --needed git
git clone https://github.com/mharshil1234/dotfiles /tmp/dotfiles
bash /tmp/dotfiles/.bootstrap/install.sh
```

The repo is private, so `git clone` asks you to sign in. Use your GitHub username with a [personal access token](https://github.com/settings/tokens) as the password, or run `gh auth login` first.

### What the installer does
1. **Restores the dotfiles** into your home folder as a bare repo (`~/.dotfiles`). Any default files in the way are moved to `~/.dotfiles-conflicts/`.
2. **Installs yay** (AUR helper).
3. **Installs my official-repo packages** from `.bootstrap/packages-repo.txt`, skipping any that no longer exist.
4. **Builds the desktop packages** from `.bootstrap/pkgbuilds/` (Hyprland, Quickshell, fonts, themes, portals, screenshot tools and so on).
5. **Installs my AUR apps** from `.bootstrap/packages-aur.txt` (Chrome, Brave, Zen, Postman, …).
6. **Creates the Python environment** the shell needs (`~/.local/state/quickshell/.venv`), and **installs Spicetify**. If Spotify has already been opened once, it also applies the MaterialYou theme.
7. **Sets up the system:** `video`/`i2c`/`input` groups, `i2c-dev`, ydotool and Bluetooth.
8. **Applies my tweaks:** power-profiles-daemon instead of TLP, the ufw firewall, reflector mirrors (India/Singapore), weekly package-cache cleanup, and the Plasma Login Manager.
9. **Sets the theme defaults:** adw-gtk3-dark and the Bibata cursor.

The installer is safe to re-run: it skips anything already done and lists whatever failed at the end.

### Finish by hand (the installer reminds you)
1. Reboot, and log in to the **Hyprland** session.
2. Generate colors from the wallpaper:
   ```bash
   ~/.config/quickshell/ii/scripts/colors/switchwall.sh --noswitch
   ```
3. **Auto-login to the lock screen:** run `kcmshell6 kcm_plasmalogin`, turn on automatic login for your user, and pick session **Hyprland**.
4. **Snapshots:** run `sudo timeshift-launcher`, choose RSYNC on the root partition, exclude home folders, and schedule Daily (keep 5) and Weekly (keep 3).
5. **Cisco Packet Tracer** needs a manual download from Cisco.
6. **Spotify theme:** if the installer skipped it, open Spotify once and log in, close it, then run `spicetify backup apply`. Run that again after every Spotify update.

## What's in here

| Area | Where | Notes |
|---|---|---|
| Installer | `.bootstrap/` | `install.sh`, package lists, end-4's PKGBUILDs, Python requirements, reflector config |
| Hyprland | `.config/hypr/` | My changes are in `custom/`: startup apps, `Super+Shift+1–9`, kitty-first terminal, cursor env, hyprlock fallback. The gesture change stays in `hyprland/general.lua` because Hyprland can't remove a default gesture from `custom/`. |
| Shell (Quickshell `ii`) | `.config/quickshell/` | Custom lock screen in `modules/ii/lock/LockSurface.qml`: centered clock, greeting, date, stats bar, a Spotify-only media card, and power buttons bottom-right. Custom "islands" top bar in `modules/ii/bar/IslandBarContent.qml` (to go back to the stock bar, change `IslandBarContent` to `BarContent` in `Bar.qml`) |
| Shell settings | `.config/illogical-impulse/config.json` | Lock on startup is on; weather uses IP location (GPS off) |
| Colors | `.config/matugen/` | Templates that turn the wallpaper into colors for every app |
| Wallpaper | `Pictures/Wallpapers/` | |
| Terminal | `.config/kitty/`, `.config/foot/`, `.config/fish/`, `.config/starship.toml`, `.config/fastfetch/` | fish for interactive use; bash stays the login shell |
| Theme | `.config/gtk-3.0/`, `.config/gtk-4.0/`, `.config/Kvantum/`, `.config/kdeglobals`, `.config/darklyrc`, `.config/kcminputrc`, `.config/qt6ct/`, `.config/xsettingsd/`, `.gtkrc-2.0`, `.icons/default/` | adw-gtk3 with wallpaper colors, Bibata-Modern-Classic cursor |
| Other | `.config/fuzzel/`, `.config/wlogout/`, `.config/mpv/`, `.config/fontconfig/`, `.config/xdg-desktop-portal/`, `.local/share/konsole/`, shell rc files, `.gitconfig`, `mimeapps.list`, browser flags | |

## Daily use

```bash
dots status                 # what changed
dots diff                   # see the changes
dots add -u                 # stage changes to tracked files
dots add <file>             # start tracking a new file
dots commit -m "message"
dots push
```

Refresh the package lists after installing or removing apps:
```bash
pacman -Qqen | grep -vx tlp | sort > ~/.bootstrap/packages-repo.txt
pacman -Qqem | grep -vE '^(illogical-impulse-|yay$|packettracer$)|-debug$' | sort > ~/.bootstrap/packages-aur.txt
```

### Updating the end-4 parts
The shell code and recipes are a snapshot of end-4's repo, so they don't update by themselves. To pull in upstream changes:
1. Clone or pull end-4's repo somewhere temporary.
2. Copy over what you want: `dots/.config/quickshell/` and the PKGBUILDs from `sdata/dist-arch/`.
3. Run `dots diff`, put back anything of mine that got overwritten (most likely the lock screen QML and `hyprland/general.lua`) with `dots checkout -- <file>`, then commit.

## Notes
- **Colors:** they come from the wallpaper. Changing the wallpaper in the shell regenerates colors for the shell, GTK, Qt, kitty and Hyprland.
- **Hardware:** the package list matches my laptop (Intel CPU and GPU drivers, `intel-ucode`). On other hardware, edit `packages-repo.txt` first.
- **Secrets:** none are stored here. The shell keeps API keys in the system keyring.

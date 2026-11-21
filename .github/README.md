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

### What the installer does
1. **Restores the dotfiles** into your home folder as a bare repo (`~/.dotfiles`). Any default files in the way are moved to `~/.dotfiles-conflicts/`. Paths in a few generated settings files are pointed at your own home folder.
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
7. **Your git identity:** it's kept out of the repo, in `~/.gitconfig.local`:
   ```bash
   git config --file ~/.gitconfig.local user.name  "Your Name"
   git config --file ~/.gitconfig.local user.email "you@example.com"
   ```

### Make it yours
- **Hardware:** the package list matches my laptop (Intel CPU/GPU, `intel-ucode`). On AMD or NVIDIA, edit `.bootstrap/packages-repo.txt` before installing.
- **Mirrors:** `.bootstrap/system/reflector.conf` picks India/Singapore mirrors. Change `--country` to yours.
- **Apps:** remove anything you don't want from `.bootstrap/packages-aur.txt` (browsers, Postman, …).
- **Wallpaper and colors:** pick a wallpaper in the shell; every app recolors to match.
- **Your own copy:** fork this repo, and set `DOTFILES_REPO=https://github.com/<you>/dotfiles.git` when running the installer so `dots push` goes to your fork.

## What's in here

| Area | Where | Notes |
|---|---|---|
| Installer | `.bootstrap/` | `install.sh`, package lists, end-4's PKGBUILDs, Python requirements, reflector config |
| Hyprland | `.config/hypr/` | My changes are in `custom/`: startup apps, `Super+Shift+1–9`, kitty-first terminal, cursor env, hyprlock fallback, Spotify window at 0.82 opacity. The gesture change stays in `hyprland/general.lua` because Hyprland can't remove a default gesture from `custom/`. |
| Top bar | `.config/quickshell/ii/modules/ii/bar/` | Custom "islands" bar (`IslandBarContent.qml` + `IslandWorkspaces`, `WindowInfo`, `SpotifyPill`, `StatusIndicators`, `BatteryPill`): launcher, window title on an 82% strip, CPU/RAM/swap rings, workspaces with app icons (numbers over the icons while Super is held), Spotify pill whose click opens the media popup under it, screenshot/keyboard/dark-mode tools, status icons, battery bar, stacked clock. To go back to the stock bar, change `IslandBarContent` to `BarContent` in `Bar.qml`. |
| Lock screen | `.config/quickshell/ii/modules/ii/lock/LockSurface.qml` | Centered clock, greeting, date, stats bar, a Spotify-only media card, power buttons bottom-right. Also shown at boot (auto-login + lock on startup). |
| Battery alerts | `.config/quickshell/ii/modules/ii/batteryWarning/` | Card at the top of the screen at 20% / 10% / 5%, suspend at 2%, "unplug" note at 80% |
| Media | `.config/quickshell/ii/modules/ii/mediaControls/` | Media popup and bar show Spotify only |
| Shell settings | `.config/illogical-impulse/config.json` | Battery thresholds, lock on startup, weather by IP location (GPS off) |
| Colors | `.config/matugen/` | Templates that turn the wallpaper into colors for every app (see Notes) |
| Wallpaper | `Pictures/Wallpapers/` | |
| Terminal | `.config/kitty/`, `.config/foot/`, `.config/fish/`, `.config/starship.toml`, `.config/fastfetch/` | kitty at 0.82 opacity with rounded tabs in wallpaper colors; fish for interactive use (bash stays the login shell), with a notification when a command of 15 s+ finishes in a terminal you're not looking at; fastfetch with the sword image logo (`sword.png`, dimmed to 70%) |
| Spotify | `.config/spicetify/` | Spicetify MaterialYou theme, colors from the wallpaper, rounded corners |
| VS Code | `.config/Code - OSS/User/settings.json` | Default Dark Modern with UI accents from the wallpaper (code area untouched), JetBrains Mono |
| Video | `.config/mpv/` | uosc controls (wallpaper colors) + thumbfast seek-bar previews |
| Other apps | `.config/btop/`, `.config/darklyrc` | btop with terminal colors and transparent background; Dolphin 80% translucent |
| Theme | `.config/gtk-3.0/`, `.config/gtk-4.0/`, `.config/Kvantum/`, `.config/kdeglobals`, `.config/qt6ct/`, `.config/xsettingsd/`, `.gtkrc-2.0`, `.icons/default/`, `.config/kcminputrc` | adw-gtk3 with wallpaper colors, Bibata-Modern-Classic cursor |
| Other | `.config/fuzzel/`, `.config/wlogout/`, `.config/fontconfig/`, `.config/xdg-desktop-portal/`, `.local/share/konsole/`, shell rc files, `.gitconfig`, `mimeapps.list`, browser flags | |

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

### Getting my latest changes on another install
After I change something and run `dots push`, update any other machine (or a fresh install) with:
```bash
dots pull                   # get the latest dotfiles
bash ~/.bootstrap/install.sh  # only if packages or the installer changed; safe to re-run
~/.config/quickshell/ii/scripts/colors/switchwall.sh --noswitch   # regenerate colors
```
The shell reloads by itself when its files change. If it doesn't, restart it:
`qs -c ii kill; hyprctl dispatch 'hl.dsp.exec_cmd("qs -c ii")'`.
For Hyprland changes, run `hyprctl reload`.

If `dots pull` refuses because of local changes, keep them with `dots stash`, run `dots pull`, then `dots stash pop`. Or throw them away with `dots checkout -- <file>`.

## Notes
- **Colors:** they come from the wallpaper. Changing the wallpaper (or dark/light mode) regenerates colors for the shell and bar, GTK, Qt, kitty (including tabs), Hyprland, Spotify, VS Code and mpv. Because of that, `gtk-4.0/gtk.css` and Spotify's `color.ini` change with every wallpaper switch; committing them is optional.
- **Secrets:** none are stored here. The shell keeps API keys in the system keyring.

#!/usr/bin/env bash
# Rebuild this whole setup on a fresh Arch Linux install.
#
#   git clone https://github.com/mharshil1234/dotfiles /tmp/dotfiles
#   bash /tmp/dotfiles/.bootstrap/install.sh
#
# Safe to re-run: every step skips what's already done.
# Includes end-4/dots-hyprland's package recipes (GPL-3.0, see pkgbuilds/LICENSE-dots-hyprland),
# so cloning end-4's repo is not needed.

set -uo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/mharshil1234/dotfiles.git}"
DOTDIR="$HOME/.dotfiles"
FAILED=()

c_info=$'\e[1;36m'; c_warn=$'\e[1;33m'; c_err=$'\e[1;31m'; c_ok=$'\e[1;32m'; c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_info" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
ok()   { printf '%s  ✓ %s%s\n' "$c_ok" "$*" "$c_off"; }
dots() { git --git-dir="$DOTDIR" --work-tree="$HOME" "$@"; }

# ── Checks ──────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && { echo "${c_err}Run as your normal user, not root.${c_off}"; exit 1; }
command -v pacman >/dev/null || { echo "${c_err}This script is for Arch Linux.${c_off}"; exit 1; }
sudo -v || exit 1
# keep sudo alive for the whole run
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

# ── 1. Dotfiles (bare repo checked out into $HOME) ──────────────────────
step "Restoring dotfiles into $HOME"
sudo pacman -S --needed --noconfirm git base-devel
if [[ ! -d "$DOTDIR" ]]; then
    git clone --bare "$REPO_URL" "$DOTDIR" || { echo "${c_err}Could not clone $REPO_URL${c_off}"; exit 1; }
fi
dots config status.showUntrackedFiles no
if ! dots checkout 2>/dev/null; then
    backup="$HOME/.dotfiles-conflicts/$(date +%Y%m%d-%H%M%S)"
    warn "Existing files would be overwritten; moving them to $backup"
    dots checkout 2>&1 | sed -n 's/^\t//p' | while read -r f; do
        mkdir -p "$backup/$(dirname "$f")"; mv "$HOME/$f" "$backup/$f"
    done
    dots checkout || { echo "${c_err}Checkout still failing, see above.${c_off}"; exit 1; }
fi
ok "Dotfiles in place"

BOOT="$HOME/.bootstrap"

# ── 2. yay (AUR helper) ────────────────────────────────────────────────
step "AUR helper (yay)"
if ! command -v yay >/dev/null; then
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" &&
        (cd "$tmp/yay-bin" && makepkg -si --noconfirm) || FAILED+=("yay")
    rm -rf "$tmp"
fi
command -v yay >/dev/null && ok "yay ready"

# ── 3. Packages from the official repos ────────────────────────────────
step "Official packages ($(grep -c . "$BOOT/packages-repo.txt") listed)"
sudo pacman -Syu --noconfirm
mapfile -t available < <(comm -12 <(sort -u "$BOOT/packages-repo.txt") <(pacman -Slq | sort -u))
mapfile -t missing   < <(comm -23 <(sort -u "$BOOT/packages-repo.txt") <(pacman -Slq | sort -u))
((${#missing[@]})) && warn "Not in the repos anymore, skipped: ${missing[*]}"
sudo pacman -S --needed --noconfirm "${available[@]}" || FAILED+=("some official packages")

# ── 4. Shell/desktop packages (end-4 illogical-impulse meta packages) ──
step "Desktop packages (Hyprland, Quickshell, fonts, themes, ...)"
for dir in "$BOOT"/pkgbuilds/illogical-impulse-*/; do
    name=$(basename "$dir")
    (
        cd "$dir" || exit 1
        # shellcheck disable=SC1091
        source ./PKGBUILD
        yay -S --needed --noconfirm --asdeps "${depends[@]}" &&
            makepkg -Afsi --noconfirm --needed
        rm -rf src pkg ./*.pkg.tar.* 2>/dev/null
    ) && ok "$name" || { warn "$name failed"; FAILED+=("$name"); }
done

# ── 5. My AUR apps ─────────────────────────────────────────────────────
step "AUR apps"
while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    yay -S --needed --noconfirm "$pkg" >/dev/null 2>&1 && ok "$pkg" || { warn "$pkg failed"; FAILED+=("$pkg"); }
done < "$BOOT/packages-aur.txt"

# ── 6. Quickshell Python environment ───────────────────────────────────
step "Python environment for the shell"
VENV="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
if [[ ! -x "$VENV/bin/python" ]]; then
    mkdir -p "$(dirname "$VENV")"
    UV_NO_MODIFY_PATH=1 uv venv --prompt .venv "$VENV" -p 3.12 &&
        VIRTUAL_ENV="$VENV" uv pip install --python "$VENV/bin/python" -r "$BOOT/python/requirements.txt" ||
        FAILED+=("python venv")
fi
[[ -x "$VENV/bin/python" ]] && ok "venv at $VENV"

# ── 6b. Spicetify (Spotify theming) ────────────────────────────────────
step "Spicetify"
yay -S --needed --noconfirm spicetify-cli >/dev/null 2>&1 && ok "spicetify-cli installed" || FAILED+=("spicetify-cli")
SPOTIFY_DIR="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"
if command -v spicetify >/dev/null && [[ -d "$SPOTIFY_DIR" && -f "$HOME/.config/spotify/prefs" ]]; then
    spicetify -q backup apply >/dev/null 2>&1 && ok "MaterialYou theme applied to Spotify" || FAILED+=("spicetify apply")
else
    warn "Spotify hasn't been opened yet, so the theme is applied later (see the list at the end)"
fi

# ── 7. System setup the shell needs ────────────────────────────────────
step "Groups, modules and services"
getent group i2c >/dev/null || sudo groupadd i2c
sudo usermod -aG video,i2c,input "$USER"
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
systemctl --user enable --now ydotool 2>/dev/null || sudo systemctl --machine="$USER@.host" --user enable ydotool
sudo systemctl enable --now bluetooth

# ── 8. My system tweaks ────────────────────────────────────────────────
step "Power, firewall, mirrors, cache cleanup"
systemctl list-unit-files tlp.service >/dev/null 2>&1 && sudo systemctl disable --now tlp 2>/dev/null
sudo systemctl enable --now power-profiles-daemon
sudo systemctl enable --now paccache.timer
sudo install -Dm644 "$BOOT/system/reflector.conf" /etc/xdg/reflector/reflector.conf
sudo systemctl enable --now reflector.timer
sudo ufw default deny incoming >/dev/null && sudo ufw default allow outgoing >/dev/null
sudo systemctl enable --now ufw && sudo ufw --force enable >/dev/null
if systemctl list-unit-files plasmalogin.service >/dev/null 2>&1; then
    sudo systemctl enable plasmalogin
fi
ok "System tweaks applied"

# ── 9. Theme defaults ──────────────────────────────────────────────────
step "Theme"
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark 2>/dev/null
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null
ok "GTK theme and cursor set"

# ── Done ───────────────────────────────────────────────────────────────
step "Finished"
if ((${#FAILED[@]})); then
    warn "These steps failed (re-run the script, or install them by hand):"
    printf '    - %s\n' "${FAILED[@]}"
fi
cat <<EOF

${c_info}A few things to do by hand:${c_off}
  1. Reboot, and log in to the "Hyprland" session.
  2. Generate the colors from the wallpaper (first login only):
       ~/.config/quickshell/ii/scripts/colors/switchwall.sh --noswitch
  3. Auto-login to the lock screen:  kcmshell6 kcm_plasmalogin
       -> automatic login, user $USER, session "Hyprland"
  4. Snapshots:  sudo timeshift-launcher
       -> RSYNC, root partition, home excluded, Daily 5 + Weekly 3
  5. Cisco Packet Tracer isn't automated (it needs a manual download from Cisco).
  6. Spotify theme (if the installer said it was skipped): open Spotify once and log in,
     close it, then run:  spicetify backup apply
     Re-run that after every Spotify update.
EOF

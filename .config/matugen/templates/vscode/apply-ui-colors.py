#!/usr/bin/env python3
"""Merge wallpaper-generated UI colors into VS Code's settings (Dark Modern only, never editor colors)."""
import json, os, sys, tempfile

THEMES = ("[Dark Modern]", "[Default Dark Modern]")  # VS Code saves either name depending on how the theme was picked
state = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
src = os.path.join(state, "quickshell/user/generated/vscode-ui-colors.json")
cfg = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
targets = [os.path.join(cfg, d, "User/settings.json") for d in ("Code - OSS", "Code", "VSCodium")]

try:
    colors = json.load(open(src))
except (OSError, ValueError) as e:
    sys.exit(f"vscode-ui: can't read {src}: {e}")
colors = {k: v for k, v in colors.items() if not k.startswith(("editor", "terminal"))}

for path in targets:
    if not os.path.isfile(path):
        continue
    try:
        settings = json.load(open(path))
    except ValueError:
        print(f"vscode-ui: skipping {path} (has comments or invalid JSON)", file=sys.stderr)
        continue
    custom = settings.setdefault("workbench.colorCustomizations", {})
    for theme in THEMES:
        custom[theme] = colors
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
    with os.fdopen(fd, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)

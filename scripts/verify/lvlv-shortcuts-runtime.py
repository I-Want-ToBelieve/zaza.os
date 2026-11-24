"""Check actual KDE shortcut assignments, including defaults outside Nix config.

Run as the desktop user after starting a fresh Plasma session. Read-only.
"""
import json
import os
from pathlib import Path
import re

config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "kglobalshortcutsrc"
bindings = {}
group = ""
for line in config.read_text(encoding="utf-8").splitlines():
    if line.startswith("["):
        group = re.findall(r"\[([^]]+)\]", line)[-1]
    elif "=" in line and not line.startswith("_"):
        action, value = line.split("=", 1)
        active = re.split(r"(?<!\\),", value, maxsplit=1)[0].replace(r"\,", ",")
        for key in re.split(r"\\t|\t", active):
            if key and key.lower() != "none":
                normalized = "+".join(sorted(key.lower().replace("control", "ctrl").split("+")))
                # KDE may store the same action in both its service and live group.
                bindings.setdefault(normalized, set()).add((group, action))
conflicts = {key: sorted(owners) for key, owners in bindings.items() if len(owners) > 1}
required = {
    "meta+space": ("plasma-manager-commands.desktop", "launch-vicinae"),
    "meta+return": ("plasma-manager-commands.desktop", "launch-kitty"),
    "ctrl+t": ("plasma-manager-commands.desktop", "toggle-kitty-quick-access"),
    "meta+v": ("plasma-manager-commands.desktop", "toggle-copyq"),
    "print": ("plasma-manager-commands.desktop", "capture-flameshot"),
    "meta+s+shift": ("plasma-manager-commands.desktop", "capture-flameshot"),
    "meta+up": ("kwin", "KrohnkiteFocusUp"),
    "meta+right": ("kwin", "KrohnkiteFocusRight"),
    "meta+p": ("kwin", "KrohnkitePreviousLayout"),
}
missing = {key: owner for key, owner in required.items() if owner not in bindings.get(key, set())}
krohnkite = {key: sorted(owners) for key, owners in bindings.items()
             if any(group == "kwin" and action.startswith("Krohnkite") for group, action in owners)}
invalid = {key: owners for key, owners in krohnkite.items()
           if len(key.split("+")) != 2 or "meta" not in key.split("+")
           or any(modifier in key.split("+") for modifier in ["alt", "ctrl", "shift"])}
result = {"shortcutCount": len(bindings), "krohnkiteCount": len(krohnkite),
          "conflicts": conflicts, "missing": missing, "invalidKrohnkiteModifiers": invalid}
print(json.dumps(result, ensure_ascii=False, indent=2))
raise SystemExit(bool(conflicts or missing or invalid or len(krohnkite) != 25))

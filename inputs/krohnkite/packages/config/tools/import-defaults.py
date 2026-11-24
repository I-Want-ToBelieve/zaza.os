"""Refresh the configuration baseline from the pinned upstream submodule."""
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

source = Path(sys.argv[1])
target = Path(__file__).resolve().parents[1] / "src" / "defaults.ts"
tree = ET.parse(source)
defaults = {}
for entry in tree.iter():
    if entry.tag.rsplit("}", 1)[-1] != "entry":
        continue
    value = next((child.text or "" for child in entry if child.tag.rsplit("}", 1)[-1] == "default"), "")
    kind = entry.attrib["type"]
    if kind == "Bool":
        value = value.strip().lower() == "true"
    elif kind in {"Int", "UInt", "Double"}:
        value = float(value) if kind == "Double" else int(value)
    defaults[entry.attrib["name"]] = value
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text("// SPDX-FileCopyrightText: 2018 Eon S. Jeon; 2024-2026 Vjatcheslav V. Kolchkov\n// SPDX-License-Identifier: MIT\n// Generated from the pinned .repo/krohnkite/res/config.xml.\nexport const rawDefaults = " + json.dumps(defaults, ensure_ascii=False, indent=2) + ";\n", encoding="utf-8")
print(f"Imported {len(defaults)} configuration defaults")

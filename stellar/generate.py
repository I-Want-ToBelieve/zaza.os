#!/usr/bin/env python3
"""Generate Noctalia v5 assets from Stellar tokens (Python 3.11+, no dependencies)."""

import argparse
import json
import math
from pathlib import Path
import re
import sys
import tomllib


ROOT = Path(__file__).resolve().parent
NOCTALIA_REV = "0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a"
PALETTE_ROLES = {
    "mPrimary": "accent",
    "mOnPrimary": "onAccent",
    "mSecondary": "success",
    "mOnSecondary": "onSuccess",
    "mTertiary": "highlight",
    "mOnTertiary": "onHighlight",
    "mError": "error",
    "mOnError": "onError",
    "mSurface": "surface",
    "mOnSurface": "text",
    "mSurfaceVariant": "raised",
    "mOnSurfaceVariant": "mutedText",
    "mOutline": "outline",
    "mShadow": "shadow",
    "mHover": "hover",
    "mOnHover": "onHover",
}


def luminance(color):
    channels = [int(color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in channels]
    return sum(v * weight for v, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def validate_tokens(tokens):
    if tokens["name"] != "Stellar" or tokens["version"] != 1:
        raise ValueError("expected Stellar token format version 1")
    for mode in ("dark", "light"):
        colors = tokens["colors"][mode]
        expected = set(PALETTE_ROLES.values()) | {"desktop"}
        if set(colors) != expected:
            raise ValueError(f"{mode}: unexpected or missing semantic color roles")
        for role, color in colors.items():
            if not isinstance(color, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
                raise ValueError(f"{mode}.{role}: expected #RRGGBB")
        for foreground, background in (
            ("text", "surface"),
            ("mutedText", "raised"),
            ("onAccent", "accent"),
            ("onSuccess", "success"),
            ("onHighlight", "highlight"),
            ("onError", "error"),
            ("onHover", "hover"),
        ):
            light, dark = sorted((luminance(colors[foreground]), luminance(colors[background])), reverse=True)
            contrast = (light + 0.05) / (dark + 0.05)
            if contrast < 4.5:
                raise ValueError(f"{mode}.{foreground}/{background}: text contrast {contrast:.2f} is below 4.5")
    for section in ("scale", "geometry", "opacity"):
        for key, value in tokens[section].items():
            if type(value) not in (int, float) or not math.isfinite(value) or value < 0:
                raise ValueError(f"{section}.{key}: expected a finite nonnegative number")
            if section == "opacity" and value > 1:
                raise ValueError(f"opacity.{key}: expected 0..1")


def build_config(t):
    g, s, o, m, font = (t[key] for key in ("geometry", "scale", "opacity", "motion", "typography"))
    return {
        "accessibility": {"ui_scale": s["ui"]},
        "shell": {
            "font_family": font["family"],
            "corner_radius_scale": s["cornerRadius"],
            "time_format": "{:%H:%M}",
            "date_format": "%A, %d %B %Y",
            "telemetry_enabled": False,
            "offline_mode": True,
            "show_location": False,
            "clipboard_enabled": False,
            "settings_show_advanced": False,
            "panel_anchor_bar": "main",
            "animation": {"enabled": m["enabled"], "speed": m["speed"]},
            "shadow": {"direction": "down", "alpha": o["shadow"]},
            "panel": {
                "transparency_mode": "solid",
                "borders": True,
                "shadow": True,
                "launcher_placement": "floating",
                "launcher_position": "center",
                "control_center_placement": "attached",
                "open_near_click_control_center": True,
            },
            "launcher": {
                "categories": False,
                "show_icons": True,
                "compact": True,
                "app_grid": False,
                "sort_by_usage": True,
                "pinned": ["foot"],
                "fetch_exchange_rates": False,
                "auto_paste": "off",
                "providers": {"calculator": {"global": True}, "session": {"global": False}},
            },
        },
        "theme": {
            "mode": "dark",
            "source": "custom",
            "custom_palette": t["name"],
            "templates": {"enable_builtin_templates": False, "enable_community_templates": False},
        },
        "wallpaper": {
            "enabled": True,
            "fill_color": "surface",
            "transition": ["fade"],
            "transition_duration": m["wallpaperTransitionMs"],
            "transition_on_startup": False,
            "default": {"path": "color:" + t["colors"]["dark"]["desktop"]},
            "automation": {"enabled": False},
        },
        "backdrop": {"enabled": False},
        "bar": {
            "main": {
                "position": "top",
                "thickness": g["barHeight"],
                "background_opacity": o["bar"],
                "radius": g["barRadius"],
                "margin_ends": g["barOuterMargin"],
                "margin_edge": g["barOuterMargin"],
                "padding": g["barPadding"],
                "widget_spacing": g["widgetSpacing"],
                "scale": s["bar"],
                "font_weight": font["barWeight"],
                "shadow": False,
                "auto_hide": False,
                "reserve_space": True,
                "capsule": False,
                "color": "on_surface",
                "icon_color": "on_surface",
                "start": ["launcher", "active_window"],
                "center": [],
                "end": ["tray", "network", "volume", "battery", "notifications", "control-center", "clock"],
            }
        },
        "widget": {
            "active_window": {
                "display": "text_only",
                "show_empty_label": False,
                "min_length": g["activeWindowMinWidth"],
                "max_length": g["activeWindowMaxWidth"],
                "title_scroll": "none",
                "font_weight": font["emphasisWeight"],
            },
            "clock": {
                "format": "{:%a %d %b  %H:%M}",
                "tooltip_format": "{:%A, %d %B %Y}",
                "font_weight": font["clockWeight"],
            },
            "network": {"show_label": False, "show_vpn_label": False},
        },
        "dock": {
            "enabled": True,
            "position": "bottom",
            "icon_size": g["dockIcon"],
            "main_axis_padding": g["dockPaddingMain"],
            "cross_axis_padding": g["dockPaddingCross"],
            "item_spacing": g["dockItemSpacing"],
            "background_opacity": o["dock"],
            "radius": g["dockRadius"],
            "margin_ends": g["dockMarginEnds"],
            "margin_edge": g["dockMarginEdge"],
            "shadow": True,
            "show_running": True,
            "auto_hide": False,
            "reserve_space": True,
            "active_scale": s["dockActive"],
            "inactive_scale": s["dockInactive"],
            "active_opacity": o["dockActive"],
            "inactive_opacity": o["dockInactive"],
            "magnification": m["dockMagnification"],
            "show_dots": True,
            "show_instance_count": False,
            "launcher_position": "start",
            "active_monitor_only": False,
            "pinned": ["foot"],
        },
        "notification": {
            "enable_daemon": True,
            "show_app_name": True,
            "show_actions": True,
            "position": "top_right",
            "scale": s["notification"],
            "background_opacity": o["popup"],
            "offset_x": g["popupMarginX"],
            "offset_y": g["popupMarginY"],
            "max_visible": 3,
            "history_retention_hours": 24,
        },
        "osd": {
            "position": "top_center",
            "scale": s["osd"],
            "background_opacity": o["popup"],
            "offset_x": g["popupMarginX"],
            "offset_y": g["popupMarginY"],
            "kinds": {"lock_keys": False, "keyboard_layout": False, "nightlight": False},
        },
        "control_center": {
            "sidebar": "compact",
            "width": g["controlCenterWidth"],
            "show_shortcut_labels": True,
            "show_session_button": True,
            "shortcuts": [{"type": name} for name in ("notification", "wallpaper", "session")],
            "calendar": {"show_events_card": False, "event_time_format": "%H:%M"},
        },
        "audio": {"enable_sounds": False, "enable_overdrive": False},
        "system": {"monitor": {"enabled": False}},
        "calendar": {"enabled": False},
        "weather": {"enabled": False},
        "location": {"auto_locate": False},
        "nightlight": {"enabled": False},
        "desktop_widgets": {"enabled": False},
    }


def toml_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (str, int, float)):
        return json.dumps(value, ensure_ascii=False, allow_nan=False)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    if isinstance(value, dict):
        return "{ " + ", ".join(f"{key} = {toml_value(item)}" for key, item in value.items()) + " }"
    raise TypeError(f"unsupported TOML value: {type(value).__name__}")


def render_toml(config):
    lines = [
        "# Generated by stellar/generate.py from stellar/tokens.json; do not edit.",
        f"# Noctalia API: {NOCTALIA_REV} (native v5).",
        "# The active-window widget is upstream window tracking, not a global AppMenu.",
        "# Validate semantics with: noctalia config validate <this-file>",
    ]

    def table(values, path):
        scalar = {key: value for key, value in values.items() if not isinstance(value, dict)}
        if scalar:
            lines.extend(("", "[" + ".".join(path) + "]"))
            lines.extend(f"{key} = {toml_value(value)}" for key, value in scalar.items())
        for key, value in values.items():
            if isinstance(value, dict):
                table(value, (*path, key))

    table(config, ())
    result = "\n".join(lines) + "\n"
    if tomllib.loads(result) != config:
        raise ValueError("generated TOML did not round-trip")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate tokens and fail if generated files have drifted")
    args = parser.parse_args()
    try:
        tokens = json.loads((ROOT / "tokens.json").read_text(encoding="utf-8"))
        validate_tokens(tokens)
        palette = {
            mode: {role: tokens["colors"][mode][semantic] for role, semantic in PALETTE_ROLES.items()}
            for mode in ("dark", "light")
        }
        outputs = {
            ROOT / "noctalia" / "config.toml": render_toml(build_config(tokens)),
            ROOT / "palettes" / "Stellar.json": json.dumps(palette, indent=2) + "\n",
        }
        stale = []
        for path, expected in outputs.items():
            if args.check:
                if not path.is_file() or path.read_text(encoding="utf-8") != expected:
                    stale.append(str(path.relative_to(ROOT)))
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(expected, encoding="utf-8", newline="\n")
        if stale:
            raise ValueError("generated files have drifted: " + ", ".join(stale) + "; run python3 stellar/generate.py")
    except (KeyError, TypeError, ValueError, OSError) as error:
        print(f"Stellar: {error}", file=sys.stderr)
        return 1
    print("Stellar tokens, text contrast, TOML syntax and generated assets: " + ("OK" if args.check else "generated"))
    return 0


if __name__ == "__main__":
    sys.exit(main())

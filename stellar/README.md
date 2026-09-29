# Stellar Shell assets

`tokens.json` owns Stellar's semantic colors, typography, dimensions, opacity and
motion. `generate.py` maps those tokens to the native Noctalia v5 configuration and
the dark/light custom palette. Edit tokens for appearance; edit `build_config()`
for behavior and widget composition.

From the repository root, with Python 3.11 or newer:

```sh
python3 stellar/generate.py
python3 stellar/generate.py --check
```

Commit both generated files. `--check` detects drift, checks all 16 palette roles,
verifies text/background contrast of at least 4.5:1, and parses the generated TOML.
The contrast check applies to palette colors before transparency/compositing; it
does not replace checking the rendered desktop. Python syntax checks do not
validate Noctalia's API. Run the pinned Linux binary separately:

```sh
noctalia config validate stellar/noctalia/config.toml
```

The Home Manager profile installs:

- `noctalia/config.toml` as `~/.config/noctalia/config.toml`.
- `palettes/Stellar.json` as `~/.config/noctalia/palettes/Stellar.json`.

Noctalia's writable state can override these files. A clean-user visual test must
therefore start without previous Noctalia state. Normal activation does not delete
the user's state. KineticWE owns the Noctalia process; these assets do not start a
second shell.

The default is dark with Inter, a full-width top bar, active-window title, status
widgets, a clock and a bottom dock. The dock pins only the `foot` terminal supplied
by the desktop profile. Panels use solid backgrounds; blur, automatic wallpaper
changes, dock magnification and continuous system-monitor sampling are disabled.
Short UI animations remain enabled. The light palette is included for later
visual validation; the desktop fill initially follows the dark baseline.

Telemetry, network-based theme generation, weather, location lookup, UI sounds
and clipboard history are disabled. `shell.offline_mode` blocks Noctalia HTTP
requests; it does not disconnect the guest or other applications. Templates are
disabled so Noctalia does not also overwrite Stylix-managed application themes.

The `active_window` widget uses upstream KWin window tracking. The global AppMenu
bridge/plugin and compositor Overview integration are separate implementation
work. This initial configuration does not claim to provide them.

API references are the exact Noctalia revision
`0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a`: `example.toml`,
`src/config/schema/config_schema.cpp`, the bar widget definitions under
`src/shell/bar/widgets/`, and `src/theme/{custom_palettes,theme_service}.cpp`.

## Session diagnostics

Run `stellar-doctor` from a terminal inside the Stellar graphical session. It
checks the current user's Wayland socket, compositor and shell process counts,
systemd user targets and failed units, notification/portal D-Bus ownership, and
the Noctalia configuration. It prints log locations and warns if GUI settings
may override the declared config, without reading the override values or logs.
It does not start services or change settings. Exit status is 0 when checks pass,
1 for session/configuration failures, and 2 for arguments or missing tools.
An existing GUI override is a warning, not a failure.

`doctor.sh` needs Bash, coreutils, procps, systemd tools and the pinned Noctalia
binary. A normal SSH or TTY session lacks the graphical session environment and
is expected to fail the Wayland checks. When validation fails, the doctor prints
the command to obtain detailed configuration diagnostics locally.

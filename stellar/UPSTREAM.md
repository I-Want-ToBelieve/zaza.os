# Stellar Shell upstream contract

Verified from the exact source archives on 2026-09-05. This document describes
the revisions in `flake.lock`, not the latest upstream documentation. Recheck
this contract when either revision changes.

| Component | Locked revision | Contract |
| --- | --- | --- |
| KineticWE | `034f787f5cba5e9b82042619d6fd167eb5f0800e` | KWin fork, session launcher, NixOS module and package overlay |
| Noctalia | `0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a` | Native C++ shell, `5.0.0` in Meson, TOML configuration, Luau plugins |

Noctalia at this revision is **not Quickshell/QML**. Its renderer uses Wayland
EGL and OpenGL ES; it builds with Meson/Ninja. See the pinned
[Meson build](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/meson.build),
[package](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/nix/package.nix)
and [renderer](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/render/backend/gles_render_backend.cpp).

## Nix and session ownership

- Import `inputs.kineticwe.nixosModules.default`, then set
  `programs.kineticwe.enable = true`. The module installs the session package,
  compositor, Noctalia, decoration library and shortcut daemon. It registers a
  `KineticWE` Wayland session and enables the KDE portal backend.
- KineticWE's `start-kineticwe` launches `kinetic-we --xwayland
  --exit-with-session <payload>`. That payload starts Noctalia in a supervisor
  loop and restarts it two seconds after exit. **Do not enable a separate
  Noctalia Home Manager service or autostart entry.**
- The session sets KDE/Wayland environment variables, imports them into D-Bus
  and the user systemd manager, and attempts to start
  `kineticwe-workspace.target`. **The pinned Nix derivations do not install
  that target**: only the Arch/RPM packaging copies it from `scripts/`.
  Stellar's NixOS integration must supply the target for
  `graphical-session.target`-bound services and XDG autostart to run. The
  pinned Nix launcher also lacks the logout target cleanup present in the
  ordinary shell launcher; verify cleanup/relogin in the VM.
- Use `inputs.kineticwe.inputs.noctalia.homeModules.default` for user config.
  No extra top-level Noctalia flake input is needed.
- Set the Home Manager package to
  `inputs.kineticwe.packages.${system}.noctalia`, matching the binary embedded
  in the session launcher. Supported package systems are `x86_64-linux` and
  `aarch64-linux`.
- KineticWE's package outputs use its own pinned nixpkgs. Do not make this
  input follow the repository's nixpkgs without separately building and
  validating the KDE/Qt combination.

Sources: pinned KineticWE
[flake](https://gitlab.com/theblackdon/kineticwe/-/blob/034f787f5cba5e9b82042619d6fd167eb5f0800e/flake.nix),
[NixOS module](https://gitlab.com/theblackdon/kineticwe/-/blob/034f787f5cba5e9b82042619d6fd167eb5f0800e/nix/nixos-module.nix),
[session](https://gitlab.com/theblackdon/kineticwe/-/blob/034f787f5cba5e9b82042619d6fd167eb5f0800e/nix/session.nix),
and Noctalia
[Home Manager module](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/nix/home-module.nix).

## Configuration and state

The upstream Home Manager module exposes `programs.noctalia.enable`,
`package`, `systemd.enable`, `settings`, `customPalettes` and `validateConfig`.
`settings` accepts an attribute set, a TOML string, or a TOML file path.
`customPalettes` is an attribute set of palette names to JSON values or paths.
`validateConfig = true` runs the pinned `noctalia config validate` at build
time before installing the resulting `~/.config/noctalia/config.toml`.

Noctalia merges the config directory's TOML files in sorted order and then
applies `~/.local/state/noctalia/settings.toml` as the final override. Home
Manager owns only the declarative config and palettes. It must not symlink,
overwrite or silently delete the mutable state file. Visual validation should
use a fresh test user/state directory so old GUI overrides cannot mask the
declarative baseline.

Custom palettes use `[theme] source = "custom"` and
`custom_palette = "Stellar"`, loading
`~/.config/noctalia/palettes/Stellar.json`. The pinned `example.toml` omits
`custom` in one comment; the schema and implementation are authoritative.

Sources:
[config schema](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/config/schema/config_schema.cpp),
[validation](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/config/config_validate.cpp),
[theme loading](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/theme/theme_service.cpp).

## Plugin and AppMenu contract

- This revision's current plugin API is **25** and it accepts APIs **3–25**.
  New Stellar plugins should declare `plugin_api = 25` and validate against
  this binary. Do not copy a newer plugin without checking its API version.
- A plugin has `plugin.toml`, an `author/plugin` ID and Luau entry files.
  Entry types include widget, panel, shortcut, desktop widget, launcher
  provider and service. Declare plugin settings in the manifest.
- Bar widgets support both imperative text/glyph updates and declarative
  `barWidget.render(tree)`. The latter can represent multiple independently
  interactive menu labels; an upstream core patch is not assumed necessary.
- `noctalia.state` shares state between the plugin's isolated entry runtimes.
  `noctalia.runStream(command, callback)` delivers stdout lines and terminates
  its child when the runtime is destroyed. At this pin it accepts a **shell
  command string**, not an argv array. Use a fixed, safely quoted bridge
  command. `noctalia.runAsync` also accepts an argv array, suitable for
  dispatching menu actions without shell interpolation.
- KineticWE exposes application menu service/path on its Plasma window
  management protocol. The application-side `kde-appmenu` protocol publishes
  that address to the compositor. A bridge still has to consume those window
  events and the exported D-Bus menu, track focus, and invoke menu actions.
  KWin script properties alone are not a proven replacement for this path.
- Noctalia's existing KWin active-window/window-list integration injects a
  KWin script through D-Bus. Reuse its app identity where appropriate, but
  validate focus and app-menu association against real Qt Wayland clients.
- Apps that do not export a menu need an app-name-only fallback.

Sources:
[plugin API versions](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/scripting/plugin_api.h),
[manifest](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/scripting/plugin_manifest.h),
[bar widget](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/shell/bar/widgets/plugin_widget.h),
[Luau host](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/scripting/luau_host.cpp),
[KWin integration](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/compositors/kde/kwin_active_window.cpp),
[KineticWE window publication](https://gitlab.com/theblackdon/kineticwe/-/blob/034f787f5cba5e9b82042619d6fd167eb5f0800e/src/window.cpp).

## Bring-up checks and known constraints

1. Build/evaluate the pinned package set before changing theme behavior.
   KineticWE additionally builds pinned development versions of kdecoration
   and kglobalacceld; both fetch from `invent.kde.org`. KWin uses
   `RelWithDebInfo`. A successful evaluation does not prove a native build.
2. With QEMU's non-GL virtio display, KWin uses `KWIN_COMPOSE=Q` and Noctalia
   still requires working Mesa software EGL/GLES. GLES 2 needs
   `GL_OES_standard_derivatives` and fragment `highp` support; GLES 3 includes
   these capabilities. Confirm the actual renderer in the Noctalia log.
   QPainter does not remove Noctalia's EGL requirement.
3. The pinned package applies `autoAddDriverRunpath`; the NixOS VM must enable
   its graphics stack so the runtime Mesa driver can be found.
4. Confirm Wayland layer-shell, a visible bar/panel/dock, IPC responses, a
   working terminal, and session recovery. Overview/window effects belong to
   KineticWE. Portals and KWin-specific features require separate smoke tests.
5. The Windows TTY host is the recovery environment. Use the separate Stellar
   graphical host with `-Graphics Vnc` for visual bring-up. This uses software
   rendering without SDL; `-Graphics Software` initializes SDL and was observed
   to freeze the guest and QMP on the current Windows host.

Sources:
[KWin derivation](https://gitlab.com/theblackdon/kineticwe/-/blob/034f787f5cba5e9b82042619d6fd167eb5f0800e/nix/kwin-we.nix),
[EGL initialization](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/render/gl_shared_context.cpp),
[GLES capability checks](https://github.com/noctalia-dev/noctalia/blob/0bf29dd9e202234cdc7fcfa6f75e938bd7fd724a/src/render/backend/gles_render_backend.cpp).

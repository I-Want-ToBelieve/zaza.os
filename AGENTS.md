# AGENTS.md

This file provides guidance to coding agents working with code in this repository.

## What this is

`zaza.os` ("ZazaOS") is one Nix flake that builds every machine its author owns: NixOS
laptops/desktops, a classroom fleet of Dell/Lenovo boxes driven over SSH, a WSL guest, a macOS
host via nix-darwin, and an Android device via nix-on-droid. There is no application code —
the deliverable is machine configuration.

The README credits [digga], but digga is not an input. The layout is **flake-parts** for output
plumbing, **haumea** for directory-to-attrset loading, **clan-core** for the NixOS machines, and
**devenv** for the dev shell.

[digga]: https://github.com/divnix/digga

## Current state (verified 2026-08-29)

### lvlv.os addition (2026-09-29)

The new `lvlv.os` physical host and `lvlv-vm` QEMU canary explicitly use minimal
upstream KDE Plasma, per the owner's current request. They share
`profiles/nixos/desktop/plasma-minimal.nix` and `hosts/nixos/lvlv/common.nix`;
the earlier Stellar decision below still applies to its existing hosts.
Neither new host selects the broad `base`, `misc`, or Home Manager application
suites. Both pass `overlays = []` to `mkHost`; existing machines retain the default
overlay list. `lvlv.os` is the flake target alias; its Clan ID and short hostname are
`lvlv`, domain `os` (Clan CLI machine IDs cannot contain dots).
Physical mount labels are a documented plan, not a Windows-discovered Linux
layout. Do not deploy to the physical NVMe without a live-ISO hardware/mount scan.
Hardware inventory and validation evidence live in `hosts/nixos/lvlv/`.
The approved applications and common CLI/TUI tools live in this host's
`applications.nix`, `terminal-tools.nix`, and `APPLICATIONS.md`; keep that selection explicit.
MacTahoe appearance is now managed by Home Manager + plasma-manager, scoped to
the normal user on these two hosts. See `profiles/home-manager/desktop/mactahoe.nix`,
`pkgs/mactahoe/default.nix`, and `hosts/nixos/lvlv/THEME.md`. Theme sources are locked
flake inputs; do not run upstream installers against a live home directory.
MacTahoe KDE and GTK are independent, default-disabled Home Manager modules in
`modules/home-manager/mactahoe-{kde,gtk}.nix`, using `appearance.mactahoe.{kde,gtk}`.
The lvlv profile enables both; GTK defaults to the light solid variant and leaves
GTK4/libadwaita CSS opt-in. Resource packages are split into `pkgs/mactahoe/{kde,gtk,icons}.nix`.
`scripts/verify/mactahoe.nix` checks independent enable flags and both color modes.
Krohnkite tiling is a separate default-disabled Home Manager module in
`modules/home-manager/krohnkite.nix`, using `programs.krohnkite`. The module keeps
`pkgs.kdePackages.krohnkite` as its default; the two lvlv hosts' shared profile now
selects `inputs.krohnkite.packages.${pkgs.stdenv.hostPlatform.system}.krohnkite`,
built from the separate Effect v4 / TypeScript monorepo, version 1.0.0.
The input is `path:./inputs/krohnkite`; its public snapshot is fixed by this OS
repository's Git commit and the per-file SHA-256 inventory in `SOURCE.json`.
The relative-path lock node records its path and dependency relationships, without
a content `narHash`. Original Codeberg and Effect sources remain submodules in
the independent project. Both lvlv users explicitly register the module and
select `profiles/home-manager/desktop/krohnkite.nix`; other hosts leave it disabled.
As of 2026-10-04, the final source passes Windows `pnpm check`, local release-asset
validation and the Linux Nix build's 329 tests. Its 350477-byte bundle has SHA-256
`4ce08863b5a109973b3753c80f3547e594b70eff78d941404b0fdd03794850b2`, identical
in Windows and Linux. The final k32brf86... package passes installed-package Qt
6.11.2 checks for partial maximization, internal-window filtering and the full
39-shortcut/12-native-window lifecycle. The sacpcjp2... VM system completed
dry-activate/test/profile/boot and a single clean Plasma login. The final live
canary passed default Tile, Monocle, return to Tile and native file reload from
8 to 16px gaps. Wrapper PID 25422 and actual compositor PID 25426 stayed the same,
with NRestarts=0 and no cleanup errors or failed system units. This proves the
tested session, not a cold boot of the final system or physical-host deployment.
The Meta-only shortcut update at source commit 120ef47 is now activated in the
6jd0q95m... VM system with the 3gzrqf3b... package. All 39 action registrations
match the shared profile: 25 unique Meta-only bindings and 14 unbound actions.
Plasma QuickTile/EditTiles conflicts are cleared; desktop selection retains
Ctrl+F1 through Ctrl+F4. Real QMP Meta+M/T events passed the geometry canary;
wrapper PID 34802 and native compositor PID 34807 stayed unchanged, with no
cleanup errors or failed units. This was Native session validation. The later
user-requested visible Native startup stalled at NetworkManager; VNC mode then
cold-booted the same 6jd0q95m... system successfully, with KWin/Shell PIDs 886/1016,
no failed user units, and two preview terminals tiled. Do not treat the VNC
cold boot as proof that visible Native startup works. TigerVNC is currently open.
The current public source snapshot contains 96 files; refresh its SOURCE.json
inventory after source commits rather than hardcoding a stale source revision.
The historical 318-test hfga package and its j5kn1a1h... VM system built, but its
native-generator pressure check failed with SIGSEGV and that system was not
activated. Its isolated KWin file-configuration smoke passed. The initial
312-test package passed the two-window Qt check and the second activation;
the earlier `81qy1459...` system is now a historical baseline. Earlier
activation attempts conflicted and rolled back. After an explicit login restart,
the manager lacked display variables while Qt/KWin had published display sockets;
a complete manager shutdown and a single login restored the environment. This is
consistent with overlapping startup/cleanup, whose full timing was not traced.
Do not claim a proven sole cause, a clean crash history for this entire boot, or
a cold boot of the final system from test/boot activation. The older stable-package checks
are historical evidence.
The original QEMU process later exited unexpectedly for an unknown reason. A
cold restart of the same disk restored the earlier `81qy1459...` baseline, with
KWin wrapper / Plasma PIDs 884 / 998. This recovery boot does not validate the
unactivated j5kn1a1h... system or the final package. The intermediate
327-test/691f121f... bundle passed Qt but later exposed partial-maximize restoration
and internal notification windows being tiled. The final version fixes both.
A diagnostic probe also crashed KWin by reading a destroyed InternalWindow's
minSize; probes now filter owned canary windows before metadata and use isolated
file caches. Final health compares the actual compositor PID, not only its wrapper.
Keep these incidents separate from the final passing session and other desktop
acceptance records. See the final receipt and geometry in the validation document.
Settings use the native user `kwinrc` group `[Script-krohnkite]`; call KWin's
`reconfigure` after file changes. Replacing the script package requires a fresh
Plasma session, whereas supported settings reload in the existing session.
The original shortcut/popup/DBus/drag-preview QML and configuration resources are
runtime assets; upstream screenshots are historical documentation images in the
Krohnkite project's `docs/images/`. Its `RESOURCE-MIGRATION.md` and `NOTICE` track
their source and attribution. See `hosts/nixos/lvlv/TILING.md`,
`hosts/nixos/lvlv/VALIDATION.md` and `scripts/verify/krohnkite.nix`.
The isolated `lvlv-vm` has now booted Plasma 6.7.5 under QEMU/WHPX with native SDL
OpenGL, and KWin reports `virgl (AMD Radeon RX 6750 XT)`. Windows SDL must omit
`usb-tablet` on the tested QEMU build to avoid a boot-time freeze; use PS/2 input.
VNC retains the tablet. The VM's `software-rendering` specialisation preserves
the earlier QPainter recovery path. Native guest warm reboot still froze after
shutdown; `-no-reboot` did not fix it and was removed. Cold boot is verified;
do not describe warm reboot as stable.
The owner replaced Ghostty with kitty; keep the default terminal and Dock in sync.
See `hosts/nixos/lvlv/VALIDATION.md` for
historical TCG failures, current checks, and the physical-host validation scope.

All configurations that predate `zaza-vm-windows`, plus
`darwinConfigurations.k99-lite-darwin`, evaluate; `nix flake check --impure` exits 0 on
darwin. This was not true between 2025-10-11 and
2026-08-29 — commit `353f738f` ("fix: types") deleted six flake inputs and fixed only the
_darwin_ config's uses of them, and reviving the tree turned out to be a chain of failures.

A multi-phase refactor took it from there to here. The plan is at
`~/.claude/plans/mcp-reactive-meerkat.md`; the phases landed on branches `refactor/p0-hygiene`
and `refactor/p1-baseline`, tagged `baseline-p1` (first evaluable state) and `baseline-p3`
(post-mkHost).

> **The real machines have no graphical session.** KDE was removed rather than migrated to
> Plasma 6, and no replacement has been chosen. Nothing has been deployed, so the tree is safe
> as it stands, but this must not reach the ten classroom machines until a desktop is picked.
>
> The exception is `zaza-vm` — an aarch64 NixOS VM on the macOS host, and the only host that
> selects a compositor. **The desktop has been chosen** (KineticWE + Noctalia, see below); the
> VM is where it gets built before it goes anywhere near a real machine. See
> [scripts/vm/README.md](scripts/vm/README.md).
>
> `zaza-vm-windows` is a separate x86_64 NixOS VM for QEMU + WHPX on Windows. It has no
> graphical session and is accessed through TTY/SSH; it intentionally does not select the
> desktop suite. Its runner and install notes are in
> [scripts/vm/windows/README.md](scripts/vm/windows/README.md).

**Nothing in this repo has been deployed to any machine.** Every phase so far is code only.

### Things that are easy to "fix" wrongly

- **`modules/nixos/gpupass.nix`** must keep the shape
  `hardware.amdgpu.initrd.enable = lib.mkIf cfg.enable (lib.mkForce false)` — not the simpler
  `lib.mkIf cfg.enable false`. `nixos-hardware`'s `common-gpu-amd` sets `mkDefault true`, which
  the `mkForce` exists to beat. Before the fix the condition sat _outside_ the `mkIf`, so
  disabling passthrough force-_enabled_ amdgpu in the initrd on seven of eight hosts, two of
  which have no AMD GPU.
- **Do not re-export `sources` from `pkgs/default.nix`.** It used to, and `callPackage` then
  injected the nvfetcher source set into every upstream package taking a `sources` argument.
  `pkgs.dart` broke on it while being fine on bare nixpkgs.
- **Do not read `config.flake.*` from `flake/hosts.nix`.** It looks like fetching one attribute
  but forces the whole flake fixpoint, and clan's `nixosConfigurations` live inside it — the
  result is `stack overflow` inside clan's `machineModules/forName.nix`. The haumea loads and
  the suites are `let` bindings in that file for exactly this reason, and re-exported as flake
  outputs from the same place.
- **`clan.specialArgs` must forward `inputs`.** Twelve host files use `inputs` inside their own
  `imports`; without it the module system falls back to `_module.args`, which needs `config`,
  which is its own guaranteed infinite recursion.

## Commands

### Dev shell

`.envrc` runs `use flake . --accept-flake-config --impure`, so `direnv allow` is the normal
entry point. Manually:

```bash
nix develop --impure --accept-flake-config
```

Provides `nvfetcher`, `zellij`, `amber-lang`, `deno` plus three devenv scripts: `hello`,
`rebuild` (the macOS switch), and `10r` (the classroom fan-out, see Fleet operations).

### Rebuild a host

`--impure` is passed everywhere out of habit; see Gotchas for whether it is actually needed.

```bash
sudo nixos-rebuild switch --flake .#xiaoxin-pro16-2021 --impure --show-trace
```

Remote — this is how the fleet is normally updated:

```bash
sudo nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.105
```

macOS:

```bash
nix run nix-darwin --accept-flake-config -- switch --flake .#k99-lite-darwin
```

**Before deploying anything to the fleet**, anchor the running system so a GC cannot collect it:

```bash
ln -sfn "$(readlink -f /run/current-system)" /nix/var/nix/gcroots/pre-refactor
```

and prefer the ladder `nixos-rebuild build` → `dry-activate` → `test` → `boot` → `switch`.
`test` activates without touching the bootloader, so a power cycle recovers — which matters
because `history.md` shows only `switch` has ever been used against these machines.

### clan

clan-core owns `nixosConfigurations`. The CLI is not yet part of the workflow because the fleet
is not modelled as clan machines (see Fleet operations), but the machines are visible to it:

```bash
nix run github:clan-lol/clan-core -- machines list
```

### Provision a brand-new machine

The `-minimal` host variants pair disko (bundled by clan-core) with nixos-anywhere:

```bash
nix run github:nix-community/nixos-anywhere -- --flake '.#dell-makcoo-minimal' --option pure-eval false --build-on-remote --print-build-logs --debug nixos@192.168.0.236
```

Target disk is overridable: `disk-config.nix` reads `_module.args.disks`, set per machine in
`flake/hosts.nix`.

### Installer ISO

```bash
nix build .#kde-plasma-iso
```

The attribute name is a misnomer since KDE was removed: it builds from
`installation-cd-minimal-new-kernel.nix` and contains no desktop. Renaming it is a user-facing
change, deliberately not done. It is gated to `x86_64-linux`.

### Formatting and checks

```bash
nix fmt
nix flake check --impure
./scripts/verify/check-undeclared-inputs.sh
./scripts/verify/lint-ratchet.sh . 48 0
./scripts/verify/equiv.sh <base-ref> [<cand-ref>]
```

`treefmt-nix` populates `formatter.<system>` (alejandra + prettier + shfmt); the exclude list
lives in the `perSystem.treefmt` block in `flake.nix` and the root `treefmt.toml` is redundant
with it. devenv's git hooks run alejandra + editorconfig-checker on **staged files only**, plus
`lint-ratchet` on the whole tree.

`scripts/verify/lint-ratchet.sh` freezes the statix/deadnix counts at **48 / 0** and fails only
when they rise. The upper bound is not zero because all 48 remaining statix findings are `W20`
(repeated keys), which statix reports but cannot fix — merging `a.b = …; a.c = …;` into
`a = { b = …; c = …; };` across two dozen files is churn with no payoff. deadnix is at a hard
zero outside `pkgs/_sources`. The built-in `statix`/`deadnix` git hooks are deliberately **not**
enabled: they demand zero findings, so the 48 would reject every commit. Raising either bound
means admitting new lint debt; lowering it is the only legitimate edit.

`scripts/verify/equiv.sh` is the equivalence harness: it checks out two refs, **refuses to run
if their `flake.lock` differ** (a differing lock makes the comparison meaningless), evaluates
both, and prints a per-host verdict with a ready-to-paste `nix-diff` command for any mismatch.
It is what proved the mkHost refactor byte-identical.

CI is `.github/workflows/check.yml`: a fast lint job, per-x86_64-host evaluation on
`ubuntu-latest`,
darwin evaluation on `macos-latest`, and `nix flake check`. It evaluates but never builds — a
runner has ~14GB of disk.

### Dependency updates

```bash
nix flake update
```

Pinned third-party sources live in `pkgs/sources.toml` — down to **two** entries,
`mpv-iptvplus` and `gtk3-nocsd`, which are exactly the two packages `pkgs/default.nix` exports.
Six others (`manix`, `swhkd`, `ecal`, `wallpaper-engine-kde-plugin`, `lightly-shaders`,
`plasma5-applets-window-appmenu`) had no consumer and were removed. Run `nvfetcher` from `pkgs/`
to regenerate `pkgs/_sources/generated.nix` (generated — never hand-edit, and it is excluded
from treefmt).

The six deletions were applied to `generated.nix`/`generated.json` **by hand**, knowingly
breaking that rule: `nvfetcher` also checks upstream for new versions, so regenerating would
have folded version bumps for the two survivors into a pure-deletion commit. The next real
`nvfetcher` run converges to the same file, minus those bumps.

### Tests

There is no test suite. `scripts/makcoo/{lock,unlock}.test.ts` are **not** `deno test` tests —
they are single-host smoke scripts with top-level `await` that fire at a production classroom
machine.

## Architecture

### `flake.nix` and `flake/hosts.nix`

`flake.nix` is ~440 lines and holds inputs, `nixConfig`, `perSystem` (devenv shell, treefmt,
checks, the ISO package), and `nixOnDroidConfigurations`. Everything about assembling machines
lives in `flake/hosts.nix`:

- the haumea directory loads and the `suites` definitions, as `let` bindings (see "easy to fix
  wrongly" above), re-exported as `flake.{modules,profiles,nixosModules,homeManagerModules,suites,overlays}`
- `mkHost` — the NixOS host factory
- `mkDarwin` / `mkDarwinModules`
- the machine table
- the `clan` block

### mkHost

A plain function with **strict named arguments**, chosen over `recursiveUpdate` over a base
attrset or a nested `evalModules` for one decisive reason: free typo detection.
`mkHost { stylyx = false; }` fails immediately with `called with unexpected argument 'stylyx'`.

It returns a **NixOS module**, not a built system, which is what lets the same function feed
`clan.machines.<name>`.

There are two booleans in the whole design — `stylix` and per-user `standardExtras`. Other
per-host exceptions are data:

- `nixos-wsl` is an entry in `modules`, not a `wsl = true` flag
- `disko` is a three-state field — `null` / `{}` / `{ disks = [...]; }` — encoding that
  `lenovo-a6-6310/disk-config.nix` takes no `disks` argument while `dell-makcoo`'s takes
  `disks ? [...]`. Passing `disks` unconditionally would suppress dell-makcoo's own default and
  crash in `elemAt`.

`system.stateVersion` is set in exactly one place, `mkHost`'s `systemStateVersion`, currently
`26.05` for every NixOS host. It used to be spread across nine sites with a load-bearing
coincidence; that is gone.

### mkDarwin returns a list, not a module

Deliberate and load-bearing. Wrapping darwin's modules in a single `{ imports = [ ... ]; }`
reorders them relative to nix-darwin's own baseModules, which reorders
`environment.systemPackages` — `nix-diff` showed `darwin-uninstaller`/`version`/`rebuild`/
`option` swapping places with `profiles/darwin/apps.nix`'s `neovim`/`git`/`skhd`. NixOS is not
sensitive to the same wrapping.

### haumea loading

`modules/{nixos,home-manager}` and `profiles/{nixos,home-manager,darwin}` are loaded with
`haumea.lib.loaders.path`, producing attrsets of **paths** mirroring the directory tree:

- `profiles/nixos/display-managers/greetd.nix` → `profiles.nixos.display-managers.greetd`
- `profiles/home-manager/shells/nu/default.nix` → `profiles.home-manager.shells.nu.default`

Add a file and the attribute appears automatically — but it is inert until a suite lists it.

### modules vs profiles

- **`modules/`** — reusable options. Every machine imports `attrValues nixosModules`
  _unconditionally_, so anything here must be self-gating with its own `enable` option.
  `modules/nixos/gpupass.nix` is the only NixOS one. `modules/home-manager/` contains
  the gated MacTahoe KDE / GTK and Krohnkite modules. Standard HM users receive them through
  `sharedModules`; minimal users such as `lvlvUsers` register them explicitly.
  Enable them only in the selected desktop profile.
- **`profiles/`** — opinionated config fragments, imported only when a suite names them.

`profiles/nixos/cachix/default.nix` auto-imports its siblings via `builtins.readDir`, so
`cachix/nix-community.nix` and `cachix/nrdxp.nix` are invisible to grep-based reasoning.

### suites

`suites.{nixos,home-manager,darwin}` are named lists of profile paths (`base`, `misc`, `games`,
`vm`, `vm-tty`, `cli`, `gui`, `shells`, `hyprland`, `darwin`).

`suites.nixos.vm` is `zaza-vm`'s, and deliberately does **not** reuse `misc`: that pulls in
NetworkManager (pointless behind QEMU's SLIRP), samba / share-via-wifi / android / chromium
(useless on a dev VM), and `games` would pull `steam`, which is x86_64-only. **A profile file has zero effect unless some
suite references it.** No host currently selects a desktop suite.

`suites.nixos.vm-tty` is the Windows VM's small add-on suite. It adds the Nix/flake profile
without importing `vm`'s locale/input-method, font, Stylix, or remote-desktop profiles. The
machine still selects `base`, so "TTY only" means no graphical session rather than a minimal
NixOS closure.

`suites.nixos.hyprland` (greetd) and `suites.home-manager.managed` (vscode) were deleted for
having zero consumers. Their profile files — `profiles/nixos/display-managers/greetd.nix` and
`profiles/home-manager/managed/vscode.nix` — are still on disk and still auto-loaded by haumea,
so reviving either is one line in `suites`. Note the asymmetry that remains:
`suites.home-manager.hyprland` **is** consumed, by `xiaoxin-pro16-2021`'s **root** user, while
nothing selects a display manager — that is the "no graphical session" state, not an oversight.

The exception to the suite rule: `profiles/home-manager/bin/*.nix` are plain string-returning
functions `import`ed directly by `profiles/home-manager/misc.nix`.

### clan

`clan-core.flakeModules.default` produces `nixosConfigurations` from `clan.machines`. It
bundles `disko` and `sops-nix`, which is why this repo declares neither. `clan.directory` is
set to a plain path and `clan.specialArgs` forwards `inputs`.

`flake/vars.nix` is a clan vars skeleton: generators for the root and user passwords that
currently sit in the tree as `initialPassword = "nixos"`. The declarations are **inert** until
someone runs `clan vars generate` — adding the file changed no drvPath. The consuming side
(`hashedPasswordFile`) is deliberately commented out, because enabling it before the vars exist
locks you out. The file carries the exact sequence.

### pkgs and overlays

`pkgs/default.nix` is itself an overlay (`final: prev: { … }`), not a package set.
`overlays/default.nix` is the last overlay in the chain.

Overlay chain: `inur` → `nvchad` → `nur` → `nvfetcher` → `rust-overlay` → `(import ../pkgs)` →
`overlays.default`. darwin swaps agenix-that-no-longer-exists for a `karabiner-elements` pin
from `nixpkgs-stable`.

`overlays/default.nix` is now an **explicitly empty** overlay. It used to be
`skhd = prev.skhd.overrideAttrs (_: _: {})` — an override changing nothing, verified byte-identical
to bare nixpkgs, which read as "skhd is patched here" when it wasn't. The file is kept rather than
deleted because `flake.overlays.default` is a public output and this is where a local package
override belongs.

### Package inventory — decisions that look wrong but aren't

`home.packages` went 161 → 133 and `systemPackages` 249 → 247 in `9cb90c5d`. Four of the
things _not_ removed are the interesting ones:

- **`pulseaudio` stays in `home.packages`.** It looks redundant next to pipewire, but no system
  package provides `pactl` — NixOS's pipewire pulse-compat layer does not install it. Removing
  it takes `pactl` off `PATH`.
- **`fzf` stays even though `programs.fzf` was deleted.** The deleted block was
  `enable = false` plus three `enableXIntegration = false` — all defaults, six no-op lines. The
  _binary_ is load-bearing: zoxide's `zi` and yazi both shell out to `fzf`.
- **`skim` stays** for the same reason: `profiles/nixos/core/common.nix`'s `manix` shellAlias
  pipes through `sk --preview=…`, system-wide, for every user.
- **`htop` is not ours to remove.** It comes from clan-core's
  `nixosModules/clanCore/defaults.nix`. The three-system-monitor situation resolves to `btop`
  (ours, kept) + `bottom` (ours, removed) + `htop` (clan's, untouchable without disabling
  clan defaults).

Also: `lm_sensors` and `wirelesstools` **are** the canonical attribute names (`lm-sensors`
does not exist — that is only the package's `name`). `utillinux` was the one real alias and is
now `util-linux`. And `networking.nftables.enable` was deliberately **not** flipped: it is the
actual iptables→nftables migration, but it moves the path docker/libvirt/waydroid depend on,
and `networking.firewall.enable = false` makes it a no-win today.

### The desktop: KineticWE + Noctalia (Stellar Shell)

**Write this down before touching desktop code.** The decision was made in conversation, then
put on hold, and was subsequently lost — a Hyprland-based VM profile got built and had to be
thrown away. It is recorded here so that cannot happen twice.

The product is **Stellar Shell**:

```
Linux → Wayland → KineticWE (a KWin fork with native tiling)
                    → Noctalia v5 (native Wayland/GLES, TOML + Luau plugins)
                      → Stellar: Top Bar / Dock / Launcher / Overview /
                                 Control Center / Notifications / Design System
```

The locked v5 is the native C++ shell; Quickshell belongs to legacy v4. See
`stellar/UPSTREAM.md` for the exact pinned configuration and plugin contracts.
Stellar assets and their generator live in `stellar/`; Home Manager installs them
through `profiles/home-manager/desktop/stellar-shell.nix`.

Two pieces of original work: **`noctalia-appmenu`** (a KWin AppMenu backend for Noctalia,
contributed upstream as a PR) and the **Stellar Design System**. The strategy is explicitly
**not to fork Noctalia** — compose upstream + theme + plugins + config + integration.

**The one decisive constraint: it must be a KWin-family compositor.** The goal is to mimic
macOS closely, and macOS's defining element is the global menu bar. The Wayland protocol that
carries it, `kde-appmenu`, is implemented **only by KWin**. Hyprland cannot provide a global
app menu at all — which is why a Hyprland desktop is not a smaller version of this plan, it is
a different plan that fails the requirement.

`inputs.kineticwe` is `gitlab:theblackdon/kineticwe`, whose own description is "a KWin window
environment (KWin fork) bundled with the noctalia shell". Facts worth knowing before editing it:

- It is a proper flake: `nixosModules.default`, `homeModules.default`, `overlays.default`,
  packages/apps/devShell, and `eachSystem` covers **`aarch64-linux`**. `programs.kineticwe.enable`
  is the single switch; it registers a real Wayland session via
  `services.displayManager.sessionPackages` and wires up `xdg-desktop-portal-kde`.
- Its own `noctalia` input points at `github:noctalia-dev/noctalia`, so "compose upstream rather
  than fork" is already how upstream builds it.
- **It has no binary cache** (`nixConfig` is absent) and it is a 624-file C++ KWin fork, so the
  guest compiles KWin from source. Budget for that, and raise `ZAZA_VM_MEM` for the first build.
- **`inputs.nixpkgs.follows` is deliberately NOT set.** It pins nixpkgs 2026-06-29 against this
  repo's 2026-08-26. Unifying them would avoid two Qt/KDE stacks in the closure, but a KWin fork
  is sensitive to KDE Frameworks versions. Upstream's tested combination comes first; revisit
  after measuring the closure, and re-verify it builds before changing that line.

### zaza-vm — the aarch64 development VM

`nixosConfigurations.zaza-vm` is the only non-x86_64 NixOS host, and the only one with a
compositor. It exists because the desktop has to be chosen somewhere, and the author's daily
machine is an Apple Silicon Mac.

Three facts that are not obvious and were each verified rather than assumed:

- **It is aarch64 because HVF requires matching architecture.** x86_64 would mean TCG
  emulation. The cost is that this VM cannot validate the classroom machines' actual closure —
  only architecture-independent desktop work transfers.
- **The VM gets a 2D-only GPU, and that is enough — because the compositor is KWin.** Homebrew's
  qemu 9.2.3 and nixpkgs' qemu 11.1.0 both lack `virtio-gpu-gl` and are not linked against
  virglrenderer (checked directly, on this host), so `virtio-gpu-pci` offers only dumb buffers.
  KWin still ships a software compositing backend — `src/backends/drm/drm_qpainter_backend.cpp`,
  selected with `KWIN_COMPOSE=Q` — which is precisely what Hyprland dropped along with pixman.
  So KWin draws straight to that framebuffer where Hyprland's DRM backend would fail.
- **The picture leaves via QEMU's own `-vnc`; the guest runs no VNC software.** An earlier
  version of this used `wayvnc`, which was simply wrong: nixpkgs describes it as a "VNC server
  for **wlroots based** Wayland compositors", and KWin is not wlroots. QEMU-side VNC also feeds
  keyboard and pointer through virtio-input for free (use `virtio-tablet`, not `virtio-mouse` —
  VNC sends absolute coordinates), and it keeps showing the boot console **when the compositor
  fails to start**, which matters more than fidelity while a desktop is being built. The noVNC
  bridge therefore runs on the **host**: `scripts/vm/run.sh novnc`.
- **The runner is deliberately outside the flake.** `scripts/vm/run.sh` is a plain QEMU
  launcher; the guest is a normal `mkHost` machine. Swapping to a runner that _can_ do 3D
  (UTM bundles a patched QEMU with virglrenderer/ANGLE) requires no guest change.

The x86-only packages are guarded **in place** — `lib.optionals onX86` splices in
`profiles/home-manager/packages.nix`, not a move to the end of the list. `home.packages` feeds
`buildEnv`'s `paths`, so order is part of the derivation; reordering would change all four
x86 hosts' drvPath. As written, they are byte-identical (verified). `mangohud` is guarded in
its own profile because on aarch64 it pulls `libstrangle`, which is x86-only — and the
resulting error names libstrangle, two layers away from the actual cause.

### zaza-vm-windows — the Windows development VM

`nixosConfigurations.zaza-vm-windows` is an x86_64 guest without a graphical session, accessed
through TTY/SSH, for QEMU 11 + WHPX. It is deliberately separate from the aarch64/macOS
`zaza-vm`; sharing a name or architecture would hide the fact that CPU acceleration and
firmware differ on the two hosts.

The guest imports nixpkgs's `qemu-guest.nix`, boots with systemd-boot from a GPT/UEFI disk, and
writes both `tty0` and `ttyS0` while keeping the serial port as `/dev/console`. The Windows
runner keeps a persistent writable copy of EDK2 vars, uses virtio for disk/network/RNG, binds
SSH only to `127.0.0.1`, and passes `-accel whpx` explicitly. Optional QMP is loopback-only and
must remain opt-in because it has no authentication. The runner must fail when WHPX is
unavailable rather than silently falling back to TCG. It defaults to a hidden, non-GL
`virtio-vga` and serial TTY; `Native`/`Angle` explicitly opt into SDL plus `virtio-vga-gl`.
The TTY configuration does not enable Mesa; add the graphics stack only when a desktop is
actually introduced. See `scripts/vm/windows/README.md`.

### zaza-vm-windows-stellar — the graphical canary

The separate x86_64 graphical host selects `suites.nixos.stellar` and
`suites.home-manager.stellar`. Its runner uses `-VmName zaza-vm-windows-stellar`;
state, qcow2, firmware vars and default SSH port (2223) are independent.
Use `-Graphics Vnc` (loopback 5911) on the current Windows host: non-GL virtio-vga
boots with WHPX, while SDL `gl=off` was observed to hang the guest and QMP.
Software/Native/Angle remain explicit experimental paths.

KWin uses QPainter and Noctalia still needs Mesa software EGL/GLES. The desktop
profile installs the workspace target missing from the upstream Nix package.
KineticWE owns the Noctalia process; its Home Manager systemd service stays off.
The HM profile disables the bundled same-name module before importing the pinned
upstream module. Graphical boot/build status belongs in `stellar/VALIDATION.md`;
configuration existing in the repository does not prove a successful desktop boot.

### Theming

**stylix** at system and HM level — catppuccin-mocha, Ubuntu Mono Ligaturized / JetBrains Mono
Nerd Font, wallpaper fetched from the author's `wallpapers` repo.
`profiles/home-manager/stylix.nix` disables eight targets, several of which (`kde`, `gtk`,
`gnome`, `xfce`) no longer have anything to theme.

`mutable/synchronous/` and its three nushell sync scripts are **gone**. It held imperative KDE
theme state and was 96,050 of the repo's 96,224 tracked files (436 MB), which made
`git worktree add` — and therefore the equivalence harness — take minutes instead of 0.06s.

### Fleet operations (`scripts/makcoo/`)

Deno + [dax]/[dzx], no `deno.json` — dependencies are URL imports. `computer.ts` is the
inventory (school → room → hosts with MAC/IP); `fn.ts` wraps
`ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa` for `lock`/`unlock`/`sleep`/`cmd`/`wakeup`/`rebuild`.

```bash
deno run --allow-all scripts/makcoo/lock.ts 10
deno run --allow-all scripts/makcoo/cmd.ts 10 "systemctl status sshd"
```

These are **kept on purpose**. clan provides no equivalent of fleet-wide
`loginctl lock-sessions` (the surviving classroom-control mechanism after Veyon was tried and
reverted), `systemctl suspend`, or Wake-on-LAN by MAC. They retire when the fleet is modelled
as clan machines, which needs an inventory this repo does not fully have — three of the ten
classroom IPs have no recorded MAC — and a machine-naming decision.

`scripts/makcoo/rebuild.ts` is broken four ways and has never run: it imports `{ computer }`
from a module that exports `schools`, its guard is inverted (`if (the_room) Deno.exit(1)`),
`the_room.hosts` therefore throws, and its `.map` callback returns nothing so `Promise.all`
resolves instantly. `fn.ts`'s `cmd` is also broken: it builds the whole command as one string
and passes it to dax as a single argv element.

[dax]: https://deno.land/x/dax
[dzx]: https://deno.land/x/dzx

## Gotchas

- **Nothing here has been deployed.** In particular the fleet still runs whatever it ran before,
  including `grub.configurationLimit = 1`.
- **`boot.loader.grub.default = "3"` is a menu _index_**, and `useOSProber` plus
  `rescue-boot.nix`'s `extraEntries` plus the raised `configurationLimit` all move what sits
  there. Ten machines boot whatever index 3 now is on a power cycle. Fixing it needs the live
  menu (`grep -n menuentry /boot/grub/grub.cfg`); the reasoning is recorded next to the line.
- **`--impure` is not required by the `builtins.fetchurl`** in the hyprland profile — it carries
  a `sha256`, which pure eval accepts. `.envrc`/devenv still pass it and every command in
  `history.md` carries it, but a pure-eval CI job is achievable.
- **`NIX_SSHOPTS` in the devenv shell hardcodes `/home/i.want.to.believe/.ssh/...`** — an
  absolute Linux path, in a shell that is also entered on macOS where the `rebuild` script runs.
  Left alone because the portable form depends on whether devenv shell-expands `env` values.
- **`nixOnDroidConfigurations` is pinned to nix-on-droid `release-24.05`**, so its
  `stateVersion` stays `24.05` while every NixOS host is on `26.05`.
- **Files on disk ≠ hosts in the flake** is no longer true — the orphans were deleted. Do not
  auto-discover hosts from `hosts/`; the machine list in `flake/hosts.nix` is explicit on
  purpose.
- **Inert profiles that grep will find but nothing imports.** `profiles/home-manager/desktop/`
  holds `sxhkd.nix` and `window-managers/niri/default.nix`, neither named by any suite;
  `display-managers/greetd.nix` and `managed/vscode.nix` likewise. haumea loads them all, so
  they appear as `profiles.*` attributes and read as live config. Only `window-managers/hyprland`
  and `mime` are actually selected (by `xiaoxin-pro16-2021`'s **root** user).
- `history.md` is a dumped shell history, not documentation, but it is the best record of which
  commands are actually used against this flake.

## Security issues present in the tree

Not introduced by any refactor; flagged so nobody assumes they are handled.

- **`assets/pems/key.pem` is a tracked private key** (rkvm TLS material). Rotating it does not
  remove it from git history.
- **One root SSH key is trusted by ~94 machines.** `users/root.nix:11` and `users/nixos.nix:11`
  carry the same `ssh-rsa` public key, labelled `thinkpad-t420s-root` for a host removed from
  the flake long ago. Its private half is distributed by `scripts/ssh.nu`, which `git clone`s a
  key repo into `~/.ssh`. Treat as compromised; it cannot be revoked from machines no longer
  under management.
- **`initialPassword = "nixos"`** for root, `i.want.to.believe`, and `nixos`, with
  `users.mutableUsers = true`. `flake/vars.nix` is the wired-but-inert replacement.
- **Two live plaintext `services.rkvm...password = "0123456789"`** in
  `hosts/nixos/xiaoxin-pro{14,16}-2021.nix`. `services.rkvm.client.settings.password` is
  `types.str` with no `passwordFile`, so pointing it at a secret store does not help — the value
  lands in the world-readable Nix store either way.
- **`networking.firewall.enable = false`** (`profiles/nixos/network.nix`) on every host that
  gets the `misc` suite, including all ten classroom machines.

## Conventions

- Formatting is **alejandra** (compact style: `{...}: {` on one line, no space inside `[a b c]`).
- `.editorconfig`: LF, UTF-8, spaces.
- Commit subjects are terse conventional-ish (`feat: …`, `fix: …`, `flake.lock: Update`).
- `main` is the PR target.
- Comments in `flake/hosts.nix` and the darwin host are frequently in Chinese; keep new comments
  in the language of their surroundings.

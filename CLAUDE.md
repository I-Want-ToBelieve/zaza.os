# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`zaza.os` ("ZazaOS") is one Nix flake that builds every machine its author owns: NixOS
laptops/desktops, a classroom fleet of Dell/Lenovo boxes driven over SSH, a WSL guest, a
macOS host via nix-darwin, and an Android device via nix-on-droid. There is no application
code — the deliverable is machine configuration.

The README credits [digga], but digga is not an input. The `modules` / `profiles` / `suites`
layout is a hand-rolled reimplementation on top of **flake-parts** (output plumbing),
**haumea** (directory-to-attrset loading) and **devenv** (dev shell + git hooks).

`flake.nix` (~1200 lines) is the _only_ wiring point. Nothing is auto-discovered: every host
is an explicit, hand-copied block.

[digga]: https://github.com/divnix/digga

## Current state (verified 2026-08-29)

All eight `nixosConfigurations` and `darwinConfigurations.k99-lite-darwin` evaluate, and
`nix flake check --impure` exits 0 on darwin. This was not true from 2025-10-11 until
2026-08-29: commit `353f738f` ("fix: types") deleted six inputs and fixed only the _darwin_
config's uses of them, and reviving it turned out to be a chain of failures, three of which
were Plasma-5-removal errors.

**KDE has been removed** rather than migrated to Plasma 6, which deleted most of that chain.
Consequence, and it matters:

> **The machines currently have no graphical session.** Nothing has been deployed, so the tree
> is safe as it stands, but this must not reach the ten classroom machines until a desktop is
> chosen. No replacement has been picked yet.

Of the three undeclared inputs, none needed restoring: `hyprpanel` is now packaged in nixpkgs
(its upstream flake's overlay is a deprecation stub), `greetd.nix` now uses `pkgs.hyprland`,
and `plasma-manager` went with KDE.

**A refactor is in progress.** The phased plan (L3 `mkHost` factory + L4' clan-core) lives at
`~/.claude/plans/mcp-reactive-meerkat.md`. Phases 0 and 1 have landed on branches
`refactor/p0-hygiene` and `refactor/p1-baseline`, the latter tagged `baseline-p1`. Read the
plan before making structural changes — several "obvious" fixes are wrong for reasons
documented there.

`scripts/verify/baseline/` records the evaluated state at that tag. Four facts in it were
previously assumed rather than known; see that directory's README. The two that constrain what
you may safely change:

- **`system.stateVersion` is `24.05` on seven hosts and `23.11` on `k99-lite-wsl` alone.** The
  flake's inline `"23.11"` is dead for the other seven (each `hosts/*.nix` `mkForce`s `"24.05"`).
  WSL works only because its host file sets a _plain_ `"23.11"` equal to the inline value — so
  "cleaning up" that inline default to `"24.05"` turns WSL into a hard eval error.
- **`modules/nixos/gpupass.nix` sets `hardware.amdgpu.initrd.enable = mkForce (!cfg.enable)`
  outside any `mkIf`**, so disabling passthrough force-_enables_ amdgpu in the initrd — measured
  `true` on seven hosts including Intel-only ones. Do not "fix" it by wrapping in
  `mkIf cfg.enable` and dropping the negation: `nixos-hardware`'s `common-gpu-amd` sets
  `mkDefault true`, which the `mkForce` exists to beat.

## Commands

### Dev shell

`.envrc` runs `use flake . --accept-flake-config --impure`, so `direnv allow` is the normal
entry point. Manually:

```bash
nix develop --impure --accept-flake-config
```

The devenv shell puts `nvfetcher`, `zellij`, `amber-lang` and `deno` on PATH plus three
generated scripts, defined in `perSystem.devenv.shells.default.scripts`:

| script    | what it does                                                                                                                              |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `hello`   | prints `$GREET`                                                                                                                           |
| `rebuild` | `nix run nix-darwin -- switch --flake .#k99-lite-darwin` (macOS switch)                                                                   |
| `10r`     | opens a `zellij` session `r10` and fires ten parallel `nixos-rebuild --target-host root@192.168.0.10{0..9}` panes for the classroom fleet |

### Rebuild a host

`--impure` is mandatory (see Gotchas) — every real invocation in `history.md` carries it.

```bash
sudo nixos-rebuild switch --flake .#xiaoxin-pro16-2021 --impure --show-trace
```

Remote (this is how the fleet is normally updated):

```bash
sudo nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.105
```

macOS:

```bash
nix run nix-darwin --accept-flake-config -- switch --flake .#k99-lite-darwin
```

deploy-rs has been removed. It had one node, at `192.168.0.218` — an address that is in
neither the classroom fleet nor `scripts/makcoo/computer.ts` — and `history.md` shows its
twelve appearances are twelve consecutive failed attempts at argument passthrough, after which
it was abandoned. It never ran successfully. Use `nixos-rebuild --target-host`; for the safety
property `magicRollback` would have given, `nixos-rebuild test` activates without touching the
bootloader, so a power cycle recovers.

### Provision a brand-new machine

The `-minimal` host variants pair disko with nixos-anywhere for first install:

```bash
nix run github:nix-community/nixos-anywhere -- --flake '.#dell-makcoo-minimal' --option pure-eval false --build-on-remote --print-build-logs --debug nixos@192.168.0.236
```

Target disk is overridable: `disk-config.nix` reads `_module.args.disks` (set per host block in
`flake.nix`, default `["/dev/nvme1n1"]`).

### Installer ISO

```bash
nix build .#kde-plasma-iso
```

The attribute name is now a misnomer: with KDE gone it builds from
`installation-cd-minimal-new-kernel.nix` and contains no desktop. Renaming it is a
user-facing change and has been left alone deliberately. It is also gated to `x86_64-linux`
— it used to be evaluated on every system, and its dead nixpkgs module path made
`nix flake check` fail in 1.2s everywhere.

### Formatting and checks

```bash
nix run nixpkgs#alejandra -- .
nix flake check --impure
```

`nix fmt` works as of Phase 0 — `treefmt-nix` populates `formatter.<system>` (alejandra +
prettier + shfmt). The root `treefmt.toml` is now redundant with the `perSystem.treefmt` block
in `flake.nix`; the latter is authoritative and carries the exclude list (`pkgs/_sources/**`,
`audit.json`, `scripts/makcoo/**`, `*.js`, `*.lua`).

devenv's git hooks also run `alejandra` + `editorconfig-checker`, but on **staged files only** —
which is why many files stayed unformatted until Phase 0 ran `nix fmt` over the whole tree.

`nix flake check --impure` exits 0 on darwin, building `checks.<system>.treefmt` and
`checks.<system>.undeclared-inputs`. It still builds no host: nothing here can build
x86_64-linux on a Mac, so host builds belong on a Linux runner.

`scripts/verify/check-undeclared-inputs.sh` catches "referenced but undeclared flake input" in
~0.3s with no evaluation, and is wired as `checks.<system>.undeclared-inputs`. It would have
caught `353f738f` at commit time. Note its regex boundary deliberately excludes `-` and `.`,
otherwise its own filename (`check-undeclared-inputs.sh`) matches as an input named `sh`.

### Dependency updates

```bash
nix flake update --commit-lock-file
```

Pinned third-party sources live in `pkgs/sources.toml`; run `nvfetcher` from `pkgs/` to
regenerate `pkgs/_sources/generated.nix` (marked generated — never hand-edit).

### Tests

There is no test suite. `scripts/makcoo/{lock,unlock}.test.ts` are **not** `deno test` tests —
they are single-host smoke scripts with top-level `await` and a `deno run --allow-all` shebang.
Run one directly:

```bash
deno run --allow-all scripts/makcoo/lock.test.ts
```

## Architecture

### haumea loading

`modules/{nixos,home-manager}` and `profiles/{nixos,home-manager,darwin}` are loaded with
`haumea.lib.loaders.path`, producing attrsets of **paths** mirroring the directory tree:

- `profiles/nixos/display-managers/greetd.nix` → `self.profiles.nixos.display-managers.greetd`
- `profiles/home-manager/shells/nu/default.nix` → `self.profiles.home-manager.shells.nu.default`

Add a file and the attribute appears automatically — but it is inert until a suite lists it.

### modules vs profiles

- **`modules/`** — reusable options. Every `nixosConfiguration` imports
  `attrValues self.nixosModules` _unconditionally_, so anything here must be self-gating with
  its own `enable` option. `modules/nixos/gpupass.nix` is the one real example (VFIO GPU
  passthrough, activated via a `specialisation` in `hosts/nixos/k99-lite.nix`).
  `modules/home-manager/` is empty, so `homeManagerModules` is `{}` and the corresponding
  `attrValues` calls are no-ops.
- **`profiles/`** — opinionated config fragments, imported only when a suite names them.

### suites

`flake.suites.{nixos,home-manager,darwin}` are named lists of profile paths (`base`, `misc`,
`games`, `hyprland`, `cli`, `gui`, `shells`, `managed`, `darwin`). A host selects them by
flattening:

```nix
{ imports = with self.suites.nixos; nixpkgs.lib.flatten [base misc games]; }
```

The `kde-x11` / `kde-wayland` suites and the home-manager `wsl` suite were deleted with KDE.
No host currently selects any desktop suite; `suites.nixos.hyprland` exists but has no
consumer.

**A profile file has zero effect unless some suite references it.** Several files under
`profiles/` are currently unreferenced. The exception: `profiles/home-manager/bin/*.nix` are
plain string-returning functions `import`ed directly by
[profiles/home-manager/misc.nix](profiles/home-manager/misc.nix) to populate `~/.local/bin`.

### Host blocks

Adding a host means copying an existing block in `flake.nix` and editing it — the duplication
is by hand and by design. Each block repeats, in order:

1. `system` + `specialArgs = { suites; inputs; self; }`
2. `attrValues self.nixosModules`
3. an inline module setting `nixpkgs.hostPlatform`, the overlay chain, and `nixpkgs.config`
   (`allowUnfree`, `share.permittedInsecurePackages`)
4. the suite `imports`
5. `home-manager` / `stylix` / `agenix` (and `disko` for `-minimal`) modules, the `hosts/…` file,
   `users/…` files, and the per-user `home-manager.users.<name>` block

home-manager receives `extraSpecialArgs = { inputs = …; }` only — HM profiles cannot use `self`
or `suites`, unlike NixOS profiles.

Overlay chain order: `share.overlays` (`inur`, `nvchad`) → `nur` → `agenix` → `nvfetcher` →
`rust-overlay` → `(import ./pkgs)` → `self.overlays.default`.

### pkgs and overlays

`pkgs/default.nix` is itself an overlay (`final: prev: { … }`), not a package set.

**Do not re-export `sources` from it.** It used to, and `callPackage` then injected the
nvfetcher source set into every upstream package taking a `sources` argument — `pkgs.dart`
broke on it (`attribute 'versionUsed' missing`) while being fine on bare nixpkgs. It is now a
`let` binding passed explicitly to the two local packages that need it.

`overlays/default.nix` is the last overlay in the chain, for patching nixpkgs.

### Theming

**stylix** at system and HM level — catppuccin-mocha, Ubuntu Mono Ligaturized / JetBrains Mono
Nerd Font, wallpaper fetched from the author's `wallpapers` repo. `profiles/home-manager/stylix.nix`
disables eight targets, several of which (`kde`, `gtk`, `gnome`, `xfce`) no longer have anything
to theme.

**`mutable/synchronous/` is now dead weight.** It held imperative KDE theme state
(`color-schemes`, `kwin`, `Kvantum`, `aurorae`, …) rsync'd by `nu scripts/backup.nu` and
`nu scripts/apply.nu`, driven by `snapshot_needed` in [scripts/share.nu](scripts/share.nu).
Nothing under `mutable/` was ever referenced from Nix, and with KDE gone there is nothing left
for it to sync. Those three scripts are also broken independently: `apply.nu:17` calls `copy`,
which is not a nushell command (it is `cp`), and `share.nu`'s `original` points at
`./mutable/synchronous/k99-lite`, a directory that has never existed.

### Fleet operations (`scripts/makcoo/`)

Deno + [dax]/[dzx], no `deno.json` — dependencies are URL imports. `computer.ts` is the
inventory (school → room → hosts with MAC/IP); `fn.ts` wraps `ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa`
for `lock`/`unlock`/`sleep`/`cmd`/`wakeup`/`rebuild`. The entry points take a room number:

```bash
deno run --allow-all scripts/makcoo/lock.ts 10
deno run --allow-all scripts/makcoo/cmd.ts 10 "systemctl status sshd"
```

[dax]: https://deno.land/x/dax
[dzx]: https://deno.land/x/dzx

### Stubs, not architecture

`lib/default.nix` (empty `makeExtensible`), `meta/`, `modules/flake-parts/zaza/` (`{}: {}`) and
`secrets/secrets.nix` (unfilled agenix template, all `age.secrets` uses commented out) are
scaffolding placeholders. Don't infer intent from them.

## Gotchas

- **`--impure` everywhere.** [profiles/home-manager/desktop/window-managers/hyprland/default.nix:155](profiles/home-manager/desktop/window-managers/hyprland/default.nix:155)
  calls `builtins.fetchurl`, which pure evaluation rejects. This is why `.envrc`, every
  `nixos-rebuild`, and nixos-anywhere's `--option pure-eval false` all opt out of purity.
- **Files on disk ≠ hosts in the flake.** `hosts/nixos/lenovo-makcoo/`,
  `hosts/nixos/xiaoxin-air14-2020.nix`, `hosts/nixos/NixOS.nix` and
  `hosts/virtual/machine/k99-lite-windows-vmware.nix` are referenced from nowhere. Wired hosts:
  `k99-lite`, `k99-lite-wsl`, `xiaoxin-pro14-2021`, `xiaoxin-pro16-2021`, `dell-makcoo`,
  `dell-makcoo-minimal`, `lenovo-a6-6310`, `lenovo-a6-6310-minimal`, `k99-lite-darwin`, the
  nix-on-droid default (whose `home.nix` is pulled in by its own
  `home-manager.config`, not by `flake.nix`), and `kde-plasma-iso.nix` via the
  `kde-plasma-iso` package.
- **`scripts/makcoo/rebuild.ts` is broken** in two ways: it imports `{ computer }` from
  `computer.ts`, which exports `schools`; and its guard is inverted
  (`if (the_room) Deno.exit(1)` — it bails when the room _is_ found). The sibling scripts show
  the correct shape. Use `10r` or a direct `nixos-rebuild --target-host` instead.
- **`nixOnDroidConfigurations` is pinned to nix-on-droid `release-24.05`** while `nixpkgs` tracks
  `master`; expect it to be stale.
- **`k99-lite-wsl` skips `attrValues self.nixosModules`** — the only NixOS host that does. Custom
  module options are unavailable there.
- **`nixpkgs` tracks `master`**, not a Hydra jobset, so binary-cache hits are chancy — a
  stdenv-touching commit means rebuilding the world on ten classroom machines. Lock is from
  2025-11-24. Moving to `nixos-unstable` is Phase 4.
- **No NixOS host sets `networking.hostName`.** All eight fall back to the default `nixos`.
  Consequence: `scripts/backup.nu` names its output directory with `(hostname)`, so
  `mutable/synchronous/` holds exactly one directory, `nixos/` — the whole fleet's KDE theme
  state has been overwriting one place. `scripts/share.nu`'s `original` points at
  `./mutable/synchronous/k99-lite`, which has never existed.
- **The fleet may have no rollback target.** `profiles/nixos/nix.nix` runs
  `nix.gc.options = "--delete-older-than 7d"` weekly while
  [hosts/nixos/dell-makcoo/default.nix:120](hosts/nixos/dell-makcoo/default.nix:120) sets
  `boot.loader.grub.configurationLimit = 1`. Expect one generation and zero GRUB rollback
  entries per classroom machine. Also `grub.default = "3"` is a menu _index_, and both
  `useOSProber` and `rescue-boot.nix`'s `extraEntries` can shift what index 3 is.
- **`--impure` is not required by the `builtins.fetchurl`** — it carries a `sha256`, which pure
  eval accepts (verified under `--pure-eval`). `.envrc`/devenv still pass it and every command
  in `history.md` carries it, but a pure-eval CI job is achievable.
- **Hardcoded absolute paths** referencing an older checkout location
  (`~/git.workspace/nix.workspace/zaza.os/...`) exist in
  [profiles/home-manager/desktop/plasma.nix](profiles/home-manager/desktop/plasma.nix) — a
  moved repo silently breaks those settings.
- `history.md` is a dumped shell history, not documentation, but it is the best record of which
  commands and flag combinations are actually used against this flake.

## Security issues present in the tree

Not introduced by any refactor; flagged so nobody assumes they are handled.

- **`assets/pems/key.pem` is a tracked private key** (rkvm TLS material). Rotating it does not
  remove it from git history.
- **One root SSH key is trusted by ~94 machines.** `users/root.nix:11` and `users/nixos.nix:11`
  carry the same `ssh-rsa` public key, labelled `thinkpad-t420s-root` for a host removed from
  the flake long ago. Its private half is distributed by `scripts/ssh.nu`, which `git clone`s a
  key repo into `~/.ssh`. Treat as compromised; it cannot be revoked from machines no longer
  under management.
- **`initialPassword = "nixos"`** for root, `i.want.to.believe`, and `nixos`
  (`users/*.nix`), with `users.mutableUsers = true`.
- **Three live plaintext `services.rkvm...password = "0123456789"`** in
  `hosts/nixos/xiaoxin-pro{14,16}-2021.nix` and `hosts/nixos/xiaoxin-air14-2020.nix`. Note
  `services.rkvm.client.settings.password` is `types.str` with no `passwordFile`, so pointing it
  at a secret store does not help — the value lands in the world-readable Nix store either way.
- **`networking.firewall.enable = false`** (`profiles/nixos/network.nix`) on every host that
  gets the `misc` suite, including all ten classroom machines.
- `agenix` is imported by all 8 NixOS hosts but declares **zero** secrets — every `age.secrets`
  use is commented out and `secrets/secrets.nix` has empty public keys. There is no secret
  management today.

## Conventions

- Formatting is **alejandra** (compact style: `{...}: {` on one line, no space inside `[a b c]`).
  Match it — the pre-commit hook will otherwise rewrite your diff.
- `.editorconfig`: LF, UTF-8, spaces.
- Commit subjects are terse conventional-ish (`feat: …`, `fix: …`, `flake.lock: Update`).
- Work happens on branch-per-machine lines (`dev.os`, `lvlv.os`, `xiaoxin-pro14-2021`); `main` is
  the PR target.
- Comments in `flake.nix` and the darwin host are frequently in Chinese; keep new comments in the
  language of their surroundings.

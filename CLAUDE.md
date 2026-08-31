# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

All eight `nixosConfigurations` and `darwinConfigurations.k99-lite-darwin` evaluate;
`nix flake check --impure` exits 0 on darwin. This was not true between 2025-10-11 and
2026-08-29 — commit `353f738f` ("fix: types") deleted six flake inputs and fixed only the
_darwin_ config's uses of them, and reviving the tree turned out to be a chain of failures.

A multi-phase refactor took it from there to here. The plan is at
`~/.claude/plans/mcp-reactive-meerkat.md`; the phases landed on branches `refactor/p0-hygiene`
and `refactor/p1-baseline`, tagged `baseline-p1` (first evaluable state) and `baseline-p3`
(post-mkHost).

> **The machines have no graphical session.** KDE was removed rather than migrated to Plasma 6,
> and no replacement has been chosen. Nothing has been deployed, so the tree is safe as it
> stands, but this must not reach the ten classroom machines until a desktop is picked.

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

CI is `.github/workflows/check.yml`: a fast lint job, per-host evaluation on `ubuntu-latest`,
darwin evaluation on `macos-latest`, and `nix flake check`. It evaluates but never builds — a
runner has ~14GB of disk.

### Dependency updates

```bash
nix flake update
```

Pinned third-party sources live in `pkgs/sources.toml`; run `nvfetcher` from `pkgs/` to
regenerate `pkgs/_sources/generated.nix` (generated — never hand-edit, and it is excluded from
treefmt).

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
`26.05` for all eight. It used to be spread across nine sites with a load-bearing coincidence;
that is gone.

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
  `modules/nixos/gpupass.nix` is the only one. `modules/home-manager/` is empty, so
  `homeManagerModules` is `{}`.
- **`profiles/`** — opinionated config fragments, imported only when a suite names them.

`profiles/nixos/cachix/default.nix` auto-imports its siblings via `builtins.readDir`, so
`cachix/nix-community.nix` and `cachix/nrdxp.nix` are invisible to grep-based reasoning.

### suites

`suites.{nixos,home-manager,darwin}` are named lists of profile paths (`base`, `misc`, `games`,
`hyprland`, `cli`, `gui`, `shells`, `managed`, `darwin`). **A profile file has zero effect
unless some suite references it.** No host currently selects a desktop suite;
`suites.nixos.hyprland` exists with no consumer, kept because it is the most likely candidate
if Hyprland is chosen.

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
- **Hardcoded absolute paths** referencing an older checkout location
  (`~/git.workspace/nix.workspace/zaza.os/...`) exist in
  [profiles/home-manager/desktop/plasma.nix](profiles/home-manager/desktop/plasma.nix) — a moved
  repo silently breaks those settings. That file also pins a `/nix/store` hash for
  `breeze-qt5-5.27.10`.
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

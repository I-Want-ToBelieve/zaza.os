# Baseline snapshot

Point-in-time evaluation of all eight `nixosConfigurations`, refreshed whenever a phase lands an
intentional change. It exists so `../equiv.sh` has a reference to diff against, and so the
semantic facts below are recorded rather than remembered.

- `tierA.json` — `config.system.build.toplevel.drvPath` per host. **Volatile**: every
  `flake.lock` change moves these. Only meaningful against the tag it was captured at.
- `tierC.json` — option-level fingerprint. Stable enough to review by eye, and the thing to diff
  when `tierA` moves and you need to know _what_ moved.

Earlier snapshots are in git history. `baseline-p1` is the first commit that evaluated at all;
`baseline-p3` is post-mkHost; `baseline-p7` is the fully migrated tree.

## Facts this snapshot pins down

| fact                                  | value                                                                       |
| ------------------------------------- | --------------------------------------------------------------------------- |
| `system.stateVersion`                 | `26.05` on all eight, set in exactly one place                              |
| `networking.hostName`                 | equals the machine name (it was `nixos` on every host until Phase 3)        |
| `hardware.amdgpu.initrd.enable`       | `true` only on the four hosts importing `nixos-hardware`'s `common-gpu-amd` |
| `boot.loader.grub.configurationLimit` | `20` on `dell-makcoo` (was `1`), `5` elsewhere, `100` on WSL                |
| `nix.gc.options`                      | `--delete-older-than 90d` everywhere (was `7d`)                             |

## The trap that is now gone

`system.stateVersion` used to be set in nine places: an inline `"23.11"` in the factory, seven
`lib.mkForce "24.05"` in host files that silently won over it, and one plain `"23.11"` in
`hosts/wsl/k99-lite-wsl.nix` that merged only because it happened to equal the inline value.
That coincidence was load-bearing — changing the inline default to `"24.05"`, the obvious
tidy-up, would have turned `k99-lite-wsl` into a hard evaluation error.

The eight overrides are deleted. There is nothing left to coincide.

## The trap that is still live

`modules/nixos/gpupass.nix` must keep the shape

    hardware.amdgpu.initrd.enable = lib.mkIf cfg.enable (lib.mkForce false);

and not the apparently-simpler `lib.mkIf cfg.enable false`. `nixos-hardware`'s `common-gpu-amd`
sets `mkDefault true`, which the `mkForce` exists to beat. Before Phase 3 the condition sat
_outside_ the `mkIf`, so disabling passthrough force-_enabled_ amdgpu in the initrd — on seven
of eight hosts, two of which have no AMD GPU at all.

## What still needs action

The rollback substrate is fixed **in code only**. Nothing in this repository has been deployed,
so the classroom machines still run with `configurationLimit = 1` and weekly
`--delete-older-than 7d` — they plausibly still have one generation and no rollback target.
Anchor the running system before deploying anything to them:

    ln -sfn "$(readlink -f /run/current-system)" /nix/var/nix/gcroots/pre-refactor

and recover with

    nix-env -p /nix/var/nix/profiles/system --set /nix/var/nix/gcroots/pre-refactor
    /nix/var/nix/profiles/system/bin/switch-to-configuration switch

`boot.loader.grub.default = "3"` is still a menu index and still unfixed. Resolving it needs the
live menu (`grep -n menuentry /boot/grub/grub.cfg`), which is information this repository does
not contain.

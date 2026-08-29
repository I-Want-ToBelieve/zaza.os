# Baseline snapshot

Point-in-time evaluation of all eight `nixosConfigurations`, refreshed whenever a phase lands
an intentional change. It exists so `../equiv.sh` has a reference to diff against, and so the
semantic facts below are recorded rather than remembered.

- `tierA.json` — `config.system.build.toplevel.drvPath` per host. **Volatile**: every
  `flake.lock` change moves these. Only meaningful against the tag it was captured at.
- `tierC.json` — option-level fingerprint. Stable enough to review by eye, and the thing to
  diff when `tierA` moves and you need to know *what* moved.

Earlier snapshots are in git history; `baseline-p1` holds the state at the first commit that
evaluated at all, before the mkHost refactor.

## Facts this snapshot pins down

| fact | value |
| ---- | ----- |
| `system.stateVersion` | `24.05` on seven hosts, `23.11` on `k99-lite-wsl` alone |
| `networking.hostName` | now equals the machine name on all eight (it was `nixos` everywhere until Phase 3) |
| `hardware.amdgpu.initrd.enable` | `true` only on the four hosts that import `nixos-hardware`'s `common-gpu-amd` |
| `boot.loader.grub.configurationLimit` | **`1` on `dell-makcoo`** — the config deployed to all ten classroom machines |

## Two traps recorded here because they are easy to "fix" wrongly

**stateVersion.** The `"23.11"` that `mkHost` sets inline is dead for seven hosts — each
`hosts/*.nix` `mkForce`s `"24.05"` over it. `hosts/wsl/k99-lite-wsl.nix` sets a *plain*
`"23.11"` that merges only because it equals the inline value. Changing the inline default to
`"24.05"` turns `k99-lite-wsl` into a hard evaluation error.

**gpupass.** `modules/nixos/gpupass.nix` must keep the shape

    hardware.amdgpu.initrd.enable = lib.mkIf cfg.enable (lib.mkForce false);

and not the apparently-simpler `lib.mkIf cfg.enable false`. `nixos-hardware`'s
`common-gpu-amd` sets `mkDefault true`, which the `mkForce` exists to beat. Before Phase 3 the
condition sat *outside* the `mkIf`, so disabling passthrough force-*enabled* amdgpu in the
initrd — on seven of eight hosts, including two with no AMD GPU at all.

## The row that still needs action

`configurationLimit = 1` on `dell-makcoo`, combined with weekly
`nix.gc --delete-older-than`, is why the classroom machines plausibly have one generation and
no rollback target. Raising it is a code change; making it true on the machines requires a
deploy.

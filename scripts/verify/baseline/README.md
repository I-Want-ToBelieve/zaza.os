# Baseline snapshot

Point-in-time evaluation of all eight `nixosConfigurations`, captured at the
`baseline-*` tag that this directory was committed under. It exists so the
equivalence harness has a reference to diff against, and so the semantic facts
below are recorded rather than remembered.

- `tierA.json` — `config.system.build.toplevel.drvPath` per host. **Volatile**:
  every `flake.lock` change moves these. Only meaningful against the exact tag.
- `tierC.json` — option-level fingerprint. Stable enough to review by eye.

Facts this snapshot pins down, all previously unverified:

| fact                                  | value                                                                                                                                                                         |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `system.stateVersion`                 | `24.05` on seven hosts, `23.11` on `k99-lite-wsl` alone                                                                                                                       |
| `networking.hostName`                 | `nixos` on **all eight** — no host sets it                                                                                                                                    |
| `hardware.amdgpu.initrd.enable`       | `true` on seven, including Intel-only `dell-makcoo` and `xiaoxin-pro14-2021`; `false` only on `k99-lite-wsl`, which is the one host that omits `attrValues self.nixosModules` |
| `boot.loader.grub.configurationLimit` | `1` on `dell-makcoo` — the config deployed to all ten classroom machines — `5` elsewhere, `100` on WSL                                                                        |

The `amdgpu.initrd` row is the `gpupass` bug: `modules/nixos/gpupass.nix` sets
`hardware.amdgpu.initrd.enable = lib.mkForce (!cfg.enable)` outside any `mkIf`,
so disabling passthrough force-_enables_ amdgpu in initrd. Do not "fix" it by
wrapping in `mkIf cfg.enable` and dropping the negation: `nixos-hardware`'s
`common-gpu-amd` sets `mkDefault true`, which the `mkForce` exists to beat.

The `configurationLimit` row is why the safety-substrate phase must precede
every other deploy: combined with weekly `nix.gc --delete-older-than 7d`, the
classroom machines plausibly have one generation and no rollback target.

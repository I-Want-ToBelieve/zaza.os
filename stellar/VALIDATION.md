# Stellar validation — 2026-09-05

This file records evidence separately from implementation scope. The complete
Stellar Shell MVP is not yet accepted.

| Check | Result |
| --- | --- |
| Exact KineticWE/Noctalia source contract | Confirmed native v5, Luau API 25, TOML, single session-owned shell |
| Windows runner parameters | Passed with temporary fixtures; no installed QEMU needed for tests |
| Stellar assets | JSON/TOML syntax, token contrast and generated-file drift checks passed |
| x86_64 graphical host evaluation | Passed in the WHPX guest |
| WHPX + non-GL virtio-vga + SDL gl=off | Guest and QMP froze during boot; experimental mode |
| WHPX + non-GL virtio-vga + QEMU VNC | Booted existing NixOS disk overlay; SSH and framebuffer capture worked |
| Native Noctalia configuration validator | Pending native binary build |
| KineticWE + Stellar graphical boot | Pending native system build |
| Cold boots, interaction and session recovery | Pending graphical boot |
| AppMenu and Overview | Pending implementation and compositor validation |

The local test uses a qcow2 overlay of the installed TTY disk, with an independent
writable firmware-vars copy. The original disk is opened only as the backing
image. The running guest still identifies as `zaza-vm-windows` until the graphical
configuration is activated; a working TTY screenshot is not a Stellar screenshot.

Nix evaluation exposed two integration issues now addressed in the profiles:

- Home Manager already contains `programs/noctalia.nix`; disable that module when
  importing the exact pinned upstream module to avoid duplicate option declarations.
- The common Nix profile sets `max-jobs = "auto"`; the graphical VM explicitly
  overrides it to limit concurrent native builds.

The pinned KineticWE Nix session package calls `kineticwe-workspace.target` but
does not install it. The new desktop profile supplies the minimal user target;
the greetd wrapper stops the target on normal session exit. Actual logout and
re-login behavior remains part of the graphical acceptance tests.

Runtime captures and build logs stay outside the repository under the local
`nixos` task workspace's `artifacts/` and `state/zaza-vm-windows-stellar/` directories.

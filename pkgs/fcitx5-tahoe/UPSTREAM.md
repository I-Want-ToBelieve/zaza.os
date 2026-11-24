# Tahoe Fcitx5 theme sources

Base: https://github.com/Become-ILLUSORY/Fcitx5-MacOS-Theme
Revision: ae1d3580042785c4fba9815cffa3cf153075e47d (MIT, retained in LICENSE).
Vendored SVGs and INI files are adapted locally; no login-time downloads/installers.

Tahoe geometry and colors reference fcitx5-webview/page/macos-26.scss:
https://github.com/fcitx-contrib/fcitx5-webview/blob/master/page/macos-26.scss
15px panel radius, 13px selection radius, 0.708 panel opacity, 16px text,
12px labels, 7px horizontal padding, blue #007aff.

The SVG/INI assets remain a ClassicUI theme under the retained MIT license.
`engine.nix` also applies `candidate-grid.patch` to the flake-locked Fcitx5
5.1.22 core. That patch follows the affected upstream files' LGPL-2.1-or-later
license; the asset LICENSE does not relicense Fcitx5.
It adds opt-in `TahoeCandidateGrid` and `TahoeAnimations` settings, disabled
by default upstream and enabled only in the lvlv configuration. The wrapper
uses the normal locked addons; no global nixpkgs overlay or new flake input.

The patch adds a clickable three-column grid for the current candidate page,
preserves candidate selection/paging in Rime, and uses the existing ClassicUI
Wayland popup/scale handling. It adds a 140ms eased fade for popup appearance
and expansion; hiding remains immediate. Light/dark follows the KDE scheme.
It does not implement Apple's Liquid Glass refraction, background-driven
material changes, native continuous candidate scrolling, or exact macOS font metrics.
The validation scope and remaining limitations are recorded in
`hosts/nixos/lvlv/DESKTOP-ACCEPTANCE.md`.

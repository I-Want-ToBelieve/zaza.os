{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      # @see https://ryantm.github.io/nixpkgs/stdenv/stdenv/#:~:text=As%20described%20in%20the%20Nix%20manual%2C%20almost%20any,so%20that%20certain%20other%20setup%20can%20take%20place.
      # @see https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/desktops/plasma-5/3rdparty/addons/bismuth/default.nix#L43
      # @see https://ryantm.github.io/nixpkgs/using/overrides/#sec-pkg-overrideAttrs
      # @see https://github.com/Bismuth-Forge/bismuth/issues/474
      # @see https://github.com/Bismuth-Forge/bismuth/issues/471
      # @see https://github.com/Bismuth-Forge/bismuth/blob/ef69afe69f615149ab347e4402862ee900452a65/src/kdecoration/decoration.cpp#L63-L64
      # @see https://discourse.nixos.org/t/how-to-patch-in-an-overlay/3678
      # @see https://stackoverflow.com/a/28484585
      (libsForQt5.bismuth.overrideAttrs (finalAttrs: previousAttrs: {
        patches = (previousAttrs.patches or [ ]) ++ [
          (fetchpatch {
            name = "bismuth-3.1-4-border-color.patch";
            url =
              "https://github.com/I-Want-ToBelieve/bismuth/commit/dac110934fe1ae0da9e4aca8c331f27987b033cf.patch";
            sha256 = "sha256-3fQs/A4hc/qeiu+792nZBTl4ujg8rQD25kuwNr03YUs=";
          })
          (fetchpatch {
            name = "bismuth-3.1-4-static-block.patch";
            url =
              "https://github.com/I-Want-ToBelieve/bismuth/commit/99438b55a82f90d4df3653d00f1f0978eddc2725.patch";
            sha256 = "sha256-jEt0YdS7k0bJRIS0UMY21o71jgrJcwNp3gFA8e8TG6I=";
          })
          (fetchpatch {
            name = "bismuth-3.1-4-window-id.patch";
            url =
              "https://github.com/jkcdarunday/bismuth/commit/ce377a33232b7eac80e7d99cb795962a057643ae.patch";
            sha256 = "sha256-15txf7pRhIvqsrBdBQOH1JDQGim2Kh5kifxQzVs5Zm0=";
          })
        ];
      }))
    ];
}

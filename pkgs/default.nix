final: prev: {
  # keep sources this first
  sources = prev.callPackage (import ./_sources/generated.nix) {};

  mpv-iptvplus =
    prev.callPackage ./applications/video/mpv/scripts/mpv-iptvplus.nix {};

  gtk3-nocsd = prev.callPackage ./development/libraries/gtk3-nocsd.nix {};
}

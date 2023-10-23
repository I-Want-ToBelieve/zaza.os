final: prev: {
  # keep sources this first
  sources = prev.callPackage (import ./_sources/generated.nix) {};

  # then, call packages with `final.callPackage`
  swhkd = prev.callPackage ./applications/window-managers/swhkd {};

  mpv-iptvplus =
    prev.callPackage ./applications/video/mpv/scripts/mpv-iptvplus.nix {};
  wallpaper-engine-kde-plugin =
    prev.plasma5Packages.callPackage
    ./desktops/plasma-5/3rdparty/addons/wallpaper-engine-kde-plugin.nix {};
  gtk3-nocsd = prev.callPackage ./development/libraries/gtk3-nocsd.nix {};

  lightly-shaders =
    prev.callPackage ./desktops/plasma-5/3rdparty/addons/lightly-shaders.nix
    {};

  plasma5-applets-window-appmenu =
    prev.plasma5Packages.callPackage
    ./desktops/plasma-5/3rdparty/addons/plasma5-applets-window-appmenu.nix {};
}

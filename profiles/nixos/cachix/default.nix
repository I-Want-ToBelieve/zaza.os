{
  pkgs,
  lib,
  ...
}: let
  folder = ./.;
  toImport = name: value: folder + ("/" + name);
  filterCaches = key: value:
    value == "regular" && lib.hasSuffix ".nix" key && key != "default.nix";
  imports =
    lib.mapAttrsToList toImport
    (lib.filterAttrs filterCaches (builtins.readDir folder));
in {
  inherit imports;
  nix.settings.substituters = lib.mkForce [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    # "https://cache.nixos.org/"
  ];
}

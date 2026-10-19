{lib, ...}: let
  folder = ./.;
  toImport = name: _value: folder + ("/" + name);
  filterCaches = key: value:
    value == "regular" && lib.hasSuffix ".nix" key && key != "default.nix";
  imports =
    lib.mapAttrsToList toImport
    (lib.filterAttrs filterCaches (builtins.readDir folder));
in {
  inherit imports;
  # 这里刻意**不**再设 substituters。
  #
  # 原本这里有一份与 profiles/nixos/nix.nix:62 逐字相同的 mkForce 列表。
  # NixOS 的 listOf str 是**拼接**语义，mkForce 只定优先级、不去重，于是
  # 两份叠加成六项、三个镜像各出现两次。nix 使用时会去重所以功能无害，
  # 但它掩盖了「有两处在争同一个设置」这件事。镜像列表归 nix.nix 管。
  #
  # 注意本目录是经 profiles/nixos/core/common.nix 的 `imports = [../cachix]`
  # 直接导入的，不经 suite —— grep suites 看不见它。
}

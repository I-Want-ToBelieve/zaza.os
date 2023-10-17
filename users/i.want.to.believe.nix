{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  mkIfLinux = lib.mkIf isLinux;
  mkIfDarwin = lib.mkIf isDarwin;
in {
  # age.secrets.i.want.to.believe.file = "${self}/secrets/i.want.to.believe.age";
  programs.fish.enable = true;

  users.mutableUsers = true;
  users.users."i.want.to.believe" = {
    description = "I Want To Believe";
    isNormalUser = true;
    shell = mkIfLinux pkgs.fish;

    initialPassword = "nixos";

    # compatibility with old drives
    uid = mkIfLinux 1000;

    # passwordFile = config.age.secrets.i.want.to.believe.path;

    home = mkIfDarwin "/Users/i.want.to.believe";
    createHome = mkIfLinux true;

    extraGroups = mkIfLinux [
      "wheel"
      "nix"
      "systemd-journal"
      "adbusers" # android bits
      "audio"
      "video"
      "dialout" # ttyACM*
      "docker"
      "libvirtd"
      "lp" # SANE
      "networkmanager"
      "piavpn"
      "render"
      "render"
      "scanner"
      "vboxusers"
      "wireshark"
      "mysql"
      "lxd" # waydroid
    ];
  };
}

{pkgs, ...}: let
  module = {
    # you will want to add options here to support your filesystem
    # and also maybe ssh to let you in
    boot.supportedFilesystems = ["btrfs" "ntfs"];
  };
  netboot = import (pkgs.path + "/nixos/lib/eval-config.nix") {
    # 不传 system 时 eval-config.nix 会退回 builtins.currentSystem，于是在 macOS 上
    # 求值这个 profile 会得到 aarch64-darwin，并因 shadow 不支持该平台而失败。
    # system = null 表示改由模块里的 nixpkgs.hostPlatform 决定，这里让它跟随
    # 目标主机的平台，而不是求值机的平台。
    system = null;
    modules = [
      {nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;}
      (pkgs.path + "/nixos/modules/installer/netboot/netboot-minimal.nix")
      module
    ];
  };
in {
  boot.loader.grub.extraEntries = ''
    menuentry "Nixos Installer" {
      linux ($drive1)/rescue-kernel init=${netboot.config.system.build.toplevel}/init ${
      toString netboot.config.boot.kernelParams
    }
      initrd ($drive1)/rescue-initrd
    }
  '';
  boot.loader.grub.extraFiles = {
    "rescue-kernel" = "${netboot.config.system.build.kernel}/bzImage";
    "rescue-initrd" = "${netboot.config.system.build.netbootRamdisk}/initrd";
  };
}

{lib, ...}: {
  imports = [./common.nix ./hardware-configuration.nix];
  networking = {
    # 单标签 hostname + domain 对应用户指定的 lvlv.os。
    hostName = "lvlv";
    domain = "os";
  };
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = true;
  };

  # Windows 上无法生成 Linux UUID。这里是预期挂载标签，不是探测结果。
  # 实机安装前合并 nixos-generate-config 的硬件结果，并替换以下挂载配置。
  fileSystems = {
    "/" = {
      device = lib.mkDefault "/dev/disk/by-label/lvlv-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = lib.mkDefault "/dev/disk/by-label/lvlv-boot";
      fsType = "vfat";
      options = ["umask=0077"];
    };
  };
}

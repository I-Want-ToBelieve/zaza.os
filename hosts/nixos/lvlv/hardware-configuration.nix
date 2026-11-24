# Windows 硬件清单的手工映射；尚未由 Linux 安装环境生成或在实体机启动。
# default.nix 的磁盘标签只是未来安装的占位约定，安装前按 HARDWARE.md 重新扫描。
{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot = {
    # B850 / Zen 5 / RTL8922AE 优先使用当前锁定 nixpkgs 的最新稳定内核。
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
    kernelModules = ["kvm-amd"];
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  swapDevices = lib.mkDefault [];

  warnings = [
    "lvlv: physical filesystem labels are provisional. Confirm the target layout and regenerate hardware configuration from a Linux live environment before installation; see hosts/nixos/lvlv/HARDWARE.md."
  ];
}

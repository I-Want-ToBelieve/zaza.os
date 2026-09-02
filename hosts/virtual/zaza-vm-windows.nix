# zaza-vm-windows —— Windows 上由 QEMU + WHPX 运行的 x86_64 NixOS 开发机。
#
# 当前没有图形会话，主要通过 TTY 与 SSH 访问。runner 默认挂载非 GL 的
# virtio-vga 并隐藏显示窗口；Native/Angle 模式才改用 virtio-vga-gl。
# TTY 阶段无需 Mesa 或 display manager。
{
  modulesPath,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./zaza-vm-windows/disk-config.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      # scripts/vm/windows/run.ps1 为这台机器保留一份可写且持久化的
      # EDK2 vars，所以 systemd-boot 可以正常写入 EFI 启动项。
      efi.canTouchEfiVariables = true;
    };

    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "sr_mod"
    ];

    # tty0 供显式启用的 SDL 模式使用；最后一个 console 是 /dev/console，
    # 对应 runner 的 `-serial mon:stdio`，默认可直接在 PowerShell 里登录。
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
    ];
  };

  # QEMU user networking (SLIRP) 会通过 DHCP 提供 10.0.2.15/24。
  # 防火墙保持开启；无论 guest 内还有哪些服务，runner 都只把 SSH 22 转发到
  # Windows 的 127.0.0.1，不向宿主局域网暴露端口。
  networking.useDHCP = lib.mkDefault true;

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

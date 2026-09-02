# zaza-vm —— macOS 上的 aarch64 NixOS 开发机，桌面选型与 shell 开发的载体。
#
# 为什么是 aarch64 而不是和其它机器一样的 x86_64：宿主是 Apple Silicon，
# 只有同架构才能用 Hypervisor.framework（HVF）做 CPU 加速。x86_64 要走 TCG
# 纯模拟，慢到没法开发桌面。代价是**这台机器验证不了教室机的真实闭包** ——
# 它只用来做与架构无关的桌面工作。
{
  modulesPath,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./zaza-vm/disk-config.nix
  ];

  # ── 引导 ────────────────────────────────────────────────────────────
  boot = {
    # aarch64 的 QEMU `virt` 机器只有 UEFI（edk2），没有传统 BIOS 可选，
    # 所以这里必须是 systemd-boot —— 不能沿用其它主机的 GRUB。
    loader = {
      systemd-boot.enable = true;
      # QEMU 每次启动都从 edk2-arm-vars.fd 复制一份临时的 EFI 变量存储，
      # 写进去的东西不保留。让 NixOS 不要去动它，否则安装期会报错。
      efi.canTouchEfiVariables = false;
    };

    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "virtio_net"
      "uas"
      "usbhid"
      "sr_mod"
    ];

    # 无头运行时唯一能看到引导过程的通道。ttyAMA0 是 aarch64 `virt` 机器的
    # PL011 串口，对应 scripts/vm/run.sh 里的 `-serial mon:stdio`。
    kernelParams = ["console=ttyAMA0,115200"];
  };

  # ── 网络 ────────────────────────────────────────────────────────────
  # QEMU 用户态网络（SLIRP）给的是 10.0.2.15/24，DHCP 即可。
  # 刻意**不用** profiles/nixos/network.nix：那份配置带 NetworkManager 和
  # 一堆物理机才需要的东西，在 SLIRP 后面只会添乱。
  networking = {
    useDHCP = lib.mkDefault true;
    # 与其它主机一致：防火墙关闭。这台机器只经 QEMU 的 hostfwd 暴露给
    # 宿主的 127.0.0.1，不在任何真实网络上。
    firewall.enable = false;
  };

  # 装机后由 nixos-anywhere 落盘，这里只声明期望值。
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}

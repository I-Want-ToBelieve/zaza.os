# zaza-vm 的磁盘布局。由 nixos-anywhere 在装机时执行，见 scripts/vm/README.md。
#
# 签名接 `disks ? [...]` —— 与 mkHost 的 disko 三态字段配套（见 flake/hosts.nix）。
# QEMU 的 virtio-blk 在 guest 里叫 /dev/vda，不是 /dev/sda。
{disks ? ["/dev/vda"], ...}: {
  disko.devices.disk.main = {
    device = builtins.elemAt disks 0;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}

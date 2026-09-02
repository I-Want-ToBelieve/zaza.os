# zaza-vm-windows 的 UEFI/GPT 磁盘布局。
# QEMU 的 virtio-blk 磁盘在 guest 内是 /dev/vda。
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

{
  lib,
  disks ? ["/dev/nvme0n1"], # --arg disks '[ "/dev/sda" ]'
  # https://github.com/nix-community/nixos-anywhere-examples/blob/37894d6ddea2beee33c7e2a9faf42d35c40c074f/flake.nix#L20
  #    { disko.devices.disk.main.device = "/dev/vda"; }
  ...
}: {
  disko.devices = {
    disk.main = {
      # device = lib.mkDefault "/dev/nvme0n1";
      # device = lib.mkDefault "/dev/sda";

      device = lib.mkDefault (builtins.elemAt disks 0);
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          plainSwap = {
            name = "swap";
            size = "6G";
            content = {
              type = "swap";
              discardPolicy = "both";
              resumeDevice = true; # resume from hiberation from this device
            };
          };
          root = {
            name = "root";
            size = "150G";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
        };
      };
    };
  };
}

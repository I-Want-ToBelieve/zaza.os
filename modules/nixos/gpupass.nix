{
  config,
  lib,
  ...
}: {
  # @see https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
  options.gpupass = {
    enable = lib.mkEnableOption (lib.mdDoc "Configure the machine for GPUPASS");

    gpuIDs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "1002:73df" # Graphics
        "1002:ab28" # Audio
      ];
      example = [
        "1002:73df" # Graphics
        "1002:ab28" # Audio
      ];
      description = ''
        how to get the ids?
        example:
        # lspci -nnv | grep AMD
        # 6750xt
      '';
    };
    vendors = lib.mkOption {
      type = lib.types.str;
      default = "AMD";
      example = "Intel";
      description = ''
        GPU vendors
      '';
    };
  };

  config = let
    cfg = config.gpupass;
  in {
    boot = {
      kernelParams =
        lib.optional cfg.enable
        # isolate the GPU
        ("vfio-pci.ids=" + lib.strings.concatStringsSep "," cfg.gpuIDs);
    };

    hardware.amdgpu.initrd.enable = lib.mkForce (!cfg.enable);
  };
}

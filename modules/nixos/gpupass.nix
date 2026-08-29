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

    # 注意这里**不能**写成天真的 `lib.mkIf cfg.enable false`：
    # nixos-hardware 的 common-gpu-amd 设了 hardware.amdgpu.initrd.enable = mkDefault true，
    # mkForce 正是为了压过它。需要的语义是「只有开启直通时才强制关掉 amdgpu 的 initrd」。
    #
    # 原来的写法把 mkForce (!cfg.enable) 放在 mkIf 之外，于是在 gpupass **关闭**时反而
    # 强制把 amdgpu 塞进 initrd —— 实测 7 台机器里连纯 Intel 的 dell-makcoo 和
    # xiaoxin-pro14-2021 都中招。
    hardware.amdgpu.initrd.enable = lib.mkIf cfg.enable (lib.mkForce false);
  };
}

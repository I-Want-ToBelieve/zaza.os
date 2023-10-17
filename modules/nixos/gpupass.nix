{ config, lib, ... }: {
  # @see https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
  options = {
    gpupass = {
      enable = lib.mkEnableOption "Configure the machine for GPUPASS";
    };
  };

  config = let
    cfg = config.gpupass;
    # lspci -nnv | grep AMD
    # AND 6750xt
    gpuIDs = [
      "1002:73df" # Graphics
      "1002:ab28" # Audio
    ];
  in {
    boot = {
      kernelParams = lib.optional cfg.enable
        # isolate the GPU
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
    };

    hardware = if cfg.enable then {
      amdgpu = {
        amdvlk = lib.mkForce false;
        opencl = lib.mkForce false;
        loadInInitrd = lib.mkForce false;
      };
    } else
      { };
  };
}

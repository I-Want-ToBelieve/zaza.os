# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports =
    [
      inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
      inputs.nixos-hardware.nixosModules.common-gpu-intel
    ]
    ++ [
      {
        hardware = {
          opengl = {enable = true;};
        };
      }
    ]
    ++ [
      {
        services.xrdp.enable = true;
        services.xrdp.defaultWindowManager = "startplasma-x11";
        services.xrdp.openFirewall = true;
      }
    ]
    ++ [
      {
        environment = {
          variables = {
            DONT_PROMPT_WSL_INSTALL = "1";
            # LD_LIBRARY_PATH = lib.mkForce "/usr/lib:$LD_LIBRARY_PATH";
          };

          sessionVariables = {
            NIXOS_OZONE_WL = "1";
          };

          systemPackages = with pkgs; [
          ];
        };
      }
    ];

  wsl = {
    enable = true;
    defaultUser = "i.want.to.believe";
    wslConf = {
      network = {
        generateHosts = false;
        generateResolvConf = false;
      };
    };
  };

  nix.settings = {
    trusted-users = ["root" "@wheel" "nixos"];
    substituters = ["https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}

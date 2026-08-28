{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  environment = {
    # we need git for flakes
    systemPackages = [pkgs.git];
    defaultPackages = [];
  };

  # faster rebuilding
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    dev.enable = false;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # pin the registry to avoid downloading and evaling a new nixpkgs version every time
    registry.nixpkgs.flake = inputs.nixpkgs;

    # set the path for channels compat
    # nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      warn-dirty = false
      keep-derivations = true
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';

    optimise.automatic = true;

    settings = {
      # Improve nix store disk usage
      sandbox = true;
      auto-optimise-store = true;
      builders-use-substitutes = true;
      trusted-users = ["root" "@wheel"];
      allowed-users = ["@wheel"];
      max-jobs = "auto";
      flake-registry = "/etc/nix/registry.json";

      # for direnv GC roots
      keep-derivations = true;
      keep-outputs = true;

      substituters = lib.mkForce [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
      ];
    };
  };
}

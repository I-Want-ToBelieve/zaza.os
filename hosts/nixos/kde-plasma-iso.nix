{
  lib,
  inputs,
  ...
}: {
  networking.networkmanager.enable = lib.mkForce false;
  networking.wireless.enable = lib.mkForce true;
  networking.wireless.userControlled.enable = true;
  networking.wireless.networks."Makcoo" = {
    psk = "makcoo888888";
  };

  services = {
    v2raya.enable = true;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # pin the registry to avoid downloading and evaling a new nixpkgs version every time
    registry = lib.mapAttrs (_: v: {flake = v;}) inputs;

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
      trusted-substituters = lib.mkForce [
        "http://192.168.0.121:8080"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}

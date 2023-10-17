{ config, pkgs, lib, inputs, ... }: {
  environment = {
    # set channels (backwards compatibility)
    etc = {
      "nix/flake-channels/system".source = inputs.self;
      "nix/flake-channels/nixpkgs".source = inputs.nixpkgs;
      "nix/flake-channels/home-manager".source = inputs.home-manager;
    };

    # we need git for flakes
    systemPackages = [ pkgs.git ];
    defaultPackages = [ ];
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
    registry = lib.mapAttrs (_: v: { flake = v; }) inputs;

    # set the path for channels compat
    # nixPath = [
    #   "nixpkgs=/etc/nix/flake-channels/nixpkgs"
    #   "home-manager=/etc/nix/flake-channels/home-manager"
    # ];

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
      trusted-users = [ "root" "@wheel" ];
      allowed-users = [ "@wheel" ];
      max-jobs = "auto";
      flake-registry = "/etc/nix/registry.json";

      # for direnv GC roots
      keep-derivations = true;
      keep-outputs = true;
    };
  };
}

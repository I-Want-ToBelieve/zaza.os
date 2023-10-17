{ inputs, ... }: { nix.nixPath = [ "home-manager=${inputs.home-manager}" ]; }

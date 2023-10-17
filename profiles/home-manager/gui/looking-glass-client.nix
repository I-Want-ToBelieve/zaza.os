{ inputs, pkgs, ... }: {
  # @see https://github.com/nix-community/home-manager/blob/master/modules/programs/looking-glass-client.nix#blob-path
  programs.looking-glass-client = { enable = true; };
}

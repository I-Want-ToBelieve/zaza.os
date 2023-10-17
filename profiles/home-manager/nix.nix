{ pkgs, inputs, ... }:
# nix tooling
{
  home = {
    packages = with pkgs; [ alejandra deadnix statix ];

    sessionVariables = { DIRENV_LOG_FORMAT = ""; };
  };
}

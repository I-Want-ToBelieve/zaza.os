{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.niri.settings = {
    outputs."eDP-1".scale = 1.5;
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  # Read the changelog before changing this value
  home = {
    stateVersion = "24.05";

    programs = {
      ssh.enable = true;

      gpg = {
        enable = true;
        homedir = "${config.xdg.dataHome}/gnupg";
      };
    };

    xdg = {
      enable = true;
      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_DEVELOPMENT_DIR = "${config.xdg.userDirs.documents}/Dev";
        };
      };
    };
  };

  # insert home-manager config
  programs.fish.enable = true;
}

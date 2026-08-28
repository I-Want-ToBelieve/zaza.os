{
  pkgs,
  config,
  ...
}: {
  home = {
    sessionPath = ["${config.home.homeDirectory}/.local/bin"];

    file = {
      ".local/bin/updoot" = {
        # Upload and get link
        executable = true;
        text = import ./bin/updoot.nix {inherit pkgs;};
      };

      ".local/bin/preview.sh" = {
        # Preview script for fzf tab
        executable = true;
        text = import ./bin/preview.nix {inherit pkgs;};
      };
    };
  };

  services = {
    syncthing.enable = true;

    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableSshSupport = true;
    };
  };

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

  gtk = {
    enable = false;
    # gtk3.extraCss = ''
    #   .titlebar, .css, headerbar{
    #     background-image:none;
    #     background-color:transparent;
    #     margin-top:-100px;
    #     margin-bottom:50px;
    #   }
    # '';
  };
}

{pkgs, ...}: {
  home.packages = with pkgs;
    [
      aria2

      bandwhich
      bc
      btop
      bottom

      cachix

      ffmpeg-full
      fzf
      flameshot

      hyperfine

      httpie # http client

      iina # video player

      lazygit

      localsend

      nil

      nix-init

      openssl

      (pkgs.python3Full.withPackages
        (pythonPackages: with pythonPackages; [requests websockets]))
      rsync
      raycast # (HotKey: alt/option + space)search, caculate and run scripts(with many plugins)
      scrcpy

      thefuck
      vscode
      xh
      xz
      duf
      du-dust
      fd
      ripgrep
    ]
    ++ (with pkgs.inur; [krabby]);

  programs = {
    eza.enable = true;

    fzf = {
      enable = false;
      enableBashIntegration = false;
      enableZshIntegration = false;
      enableFishIntegration = false;
    };

    mcfly = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
    };

    dircolors = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    bat = {enable = true;};
  };
}

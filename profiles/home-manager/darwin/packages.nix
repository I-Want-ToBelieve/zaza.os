{pkgs, ...}: {
  home.packages = with pkgs;
    [
      aria2

      bandwhich
      bc
      btop

      cachix

      ffmpeg
      fzf
      flameshot

      hyperfine

      krabby

      httpie # http client

      iina # video player

      lazygit

      localsend

      nixd # 与 NixOS 侧一致：两个 Nix LSP 留 nixd

      nix-init

      openssl

      rsync
      raycast # (HotKey: alt/option + space)search, caculate and run scripts(with many plugins)
      scrcpy

      # thefuck
      vscode
      xh
      xz
      duf
      dust
      fd
      ripgrep
    ]
    ++ (with pkgs.inur; []);

  programs = {
    eza.enable = true;

    atuin = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
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

    zellij = {
      enable = true;
    };
  };
}

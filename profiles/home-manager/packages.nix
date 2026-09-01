{
  inputs,
  lib,
  pkgs,
  ...
}: let
  # lutris / wine / leagueoflegends 只有 x86_64 版本。zaza-vm 是 aarch64
  # （宿主是 Apple Silicon，要 HVF 加速就只能同架构），不守卫会让整台机器
  # 求值失败 —— 报错还是从 mangohud 的依赖 libstrangle 那里冒出来的，
  # 与真正的原因隔着两层。
  #
  # 用原位切分而不是把它们挪到列表末尾：home.packages 会进 buildEnv 的
  # `paths`，顺序是 derivation 的一部分，挪位置会改掉四台 x86 机器的 drvPath。
  onX86 = pkgs.stdenv.hostPlatform.isx86_64;
in {
  home.packages = with pkgs;
    [
      alsa-tools
      alsa-utils

      # archivebox
      # ariang

      bandwhich
      bc
      btop
      bottom
      cached-nix-shell
      cachix

      deno
      ddcutil
      droidcam

      distrobox

      evtest
      filebrowser
      ffmpeg
      fzf
      goverlay
      gamemode
      mesa-demos # 曾名 glxinfo
      gnumake
      gnuplot
      grex

      gtk3-nocsd

      hyperfine
      imagemagick
      inotify-tools
      keepassxc
      krabby

      lazygit
      localsend
      # libreoffice-fresh
    ]
    ++ lib.optionals onX86 [lutris]
    ++ [
      moonlight-qt

      netease-cloud-music-gtk
      nodejs
      neovim
      nix-init

      obsidian

      pamixer
      piper
      psmisc
      pulseaudio

      rsync
      # rustdesk

      scrcpy
      scream

      todo
      tdrop
      # thefuck
      trash-cli
      vscode

      # my-wpsoffice
    ]
    ++ lib.optionals onX86 [
      wineWowPackages.fonts
      wineWowPackages.unstableFull
      winetricks
    ]
    ++ [
      iw # 取代 wireless-tools：iwconfig 一套早已废弃

      waypipe
      wl-clipboard # 取代 xclip：目标是 Wayland

      whitesur-gtk-theme

      xdg-utils
      xh
      xz
      xorg.xhost

      # yesplaymusic 已从 nixpkgs 移除（上游项目归档），无替代包
      yarn

      catimg
      duf
      dust
      fd
      file
      ripgrep
    ]
    ++ [
      lua-language-server
      bash-language-server # nodePackages 已整体移除，此包升到了顶层
      emmet-language-server
      nixd
    ]
    ++ lib.optionals onX86 (with pkgs.inur; [leagueoflegends])
    # xddxdd.dingtalk 已从该 NUR 仓库消失，nixpkgs 顶层也没有，无替代包。
    # 若仍需要钉钉，得自己打包或用其它渠道。
    ++ (with inputs; [autohide-tdrop.packages.${pkgs.system}.default]);

  programs = {
    eza.enable = true;

    # atuin 取代 mcfly：mcfly 上游停在 0.9.3，atuin 仍在活跃开发，
    # 且默认不联网（同步要显式配 settings.sync_address + 登录）。
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

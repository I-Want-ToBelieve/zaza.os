{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      alsa-lib
      alsa-plugins
      alsa-tools
      alsa-utils

      # archivebox
      # ariang

      bandwhich
      bc
      btop
      bottom
      cairo
      cached-nix-shell
      cachix

      coreutils
      deno
      dconf
      ddcutil
      droidcam

      distrobox

      evtest
      fuzzel
      filebrowser
      findutils
      ffmpeg
      fzf
      flameshot
      goverlay
      gamemode
      glib
      mesa-demos # 曾名 glxinfo
      gnumake
      gnuplot
      gnused
      gnutls
      grex

      gtk3-nocsd

      hyperfine
      imagemagick
      imv
      inotify-tools
      ipset
      iproute2
      iptables
      keepassxc
      killall
      kooha
      krabby

      lazygit
      libappindicator
      libnotify
      libsecret
      localsend
      # libreoffice-fresh
      lutris

      moonlight-qt

      netease-cloud-music-gtk
      nil
      nodejs
      neovim
      nix-init

      openssl
      obsidian

      pamixer
      piper
      psmisc
      pavucontrol
      pulseaudio
      qimgv

      rsync
      # rustdesk

      scrcpy
      scream

      todo
      tdrop
      # thefuck
      trash-cli
      util-linux
      vscode

      # my-wpsoffice

      wineWowPackages.fonts
      wineWowPackages.unstableFull
      winetricks
      wirelesstools

      waypipe

      whitesur-gtk-theme

      xarchiver
      xclip
      xdg-utils
      xh
      xz
      xorg.xhost

      # yesplaymusic 已从 nixpkgs 移除（上游项目归档），无替代包
      yarn

      zenity
      catimg
      duf
      dust
      fd
      file
      ripgrep
    ]
    ++ [
      lua-language-server
      nodePackages.bash-language-server
      emmet-language-server
      nixd
    ]
    ++ (with pkgs.kdePackages; [qtstyleplugin-kvantum])
    ++ (with pkgs.inur; [leagueoflegends])
    ++ (with pkgs.nur.repos; [xddxdd.dingtalk])
    ++ (with inputs; [autohide-tdrop.packages.${pkgs.system}.default]);

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

    zellij = {
      enable = true;
    };
  };
}

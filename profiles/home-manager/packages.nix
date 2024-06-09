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
      dconf
      ddcutil
      droidcam

      distrobox

      evtest
      fuzzel
      filebrowser
      filelight
      findutils
      ffmpeg-full
      fzf
      flameshot
      goverlay
      gamemode
      glib
      glxinfo
      gnumake
      gnuplot
      gnused
      gnutls
      grex

      gtk3-nocsd

      hyperfine
      imagemagick
      inotify-tools
      ipset
      iproute2
      iptables
      keepassxc
      killall

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

      pamixer
      piper
      psmisc
      pavucontrol
      pulseaudio
      qimgv
      (pkgs.python3Full.withPackages
        (pythonPackages: with pythonPackages; [requests websockets pyclip]))

      rsync
      rustdesk

      scrcpy
      scream

      todo
      tdrop
      thefuck
      trash-cli
      util-linux
      vscode

      my-wpsoffice

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
      yesplaymusic
      gnome.zenity
      catimg
      duf
      du-dust
      fd
      file
      ripgrep
    ]
    ++ (with pkgs.kdePackages; [qtstyleplugin-kvantum])
    ++ (with pkgs.inur; [krabby leagueoflegends])
    ++ (with pkgs.nur.repos; [xddxdd.baidupcs-go])
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

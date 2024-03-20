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

      android-studio

      # archivebox
      # ariang
      motrix
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

      (distrobox.overrideAttrs (finalAttrs: previousAttrs: {
        version = "1.7.0.1";
        src = fetchFromGitHub {
          owner = "89luca89";
          repo = "distrobox";
          rev = finalAttrs.version;
          hash = "sha256-mIVMy09VO8l6/wzlVUhXCq2de8xSwFU1eXMBl9S6uWU=";
        };
        patches = [];
      }))

      evtest
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
      google-chrome
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

      netease-cloud-music-gtk
      nil
      nodejs
      neovim
      nix-init
      obinskit
      openssl

      pamixer
      piper
      psmisc
      pavucontrol
      pulseaudio
      (pkgs.python3Full.withPackages
        (pythonPackages: with pythonPackages; [requests websockets]))
      rsync
      scrcpy
      scream

      todo
      tdrop
      thefuck
      trash-cli
      util-linux
      vscode

      wineWowPackages.fonts
      wineWowPackages.unstableFull
      winetricks
      wirelesstools

      xarchiver
      xclip
      xdg-utils
      xh
      xz
      xorg.xhost
      yesplaymusic
      zoom-us
      gnome.zenity
      catimg
      duf
      du-dust
      fd
      file
      ripgrep
      yt-dlp
    ]
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

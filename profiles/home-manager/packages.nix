{pkgs, ...}: {
  home.packages = with pkgs;
    [
      alsa-lib
      alsa-plugins
      alsa-tools
      alsa-utils

      archivebox
      ariang
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

      distrobox

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
      microsoft-edge
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
      (pkgs.python39.withPackages
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
      yuzu-ea
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
    ++ (with pkgs.inur; [autohide-tdrop krabby leagueoflegends])
    ++ (with pkgs.nur.repos; [xddxdd.baidupcs-go]);

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

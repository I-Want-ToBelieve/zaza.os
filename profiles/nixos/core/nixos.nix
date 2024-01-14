{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [./common.nix];

  # console = let
  #   normal = ["181825" "F38BA8" "A6E3A1" "F9E2AF" "89B4FA" "F5C2E7" "94E2D5" "BAC2DE"];
  #   bright = ["1E1E2E" "F38BA8" "A6E3A1" "F9E2AF" "89B4FA" "F5C2E7" "94E2D5" "A6ADC8"];
  # in {
  #   colors = normal ++ bright;
  #   font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  #   keyMap = "us";
  # };

  environment = {
    binsh = "${pkgs.bash}/bin/bash";
    shells = with pkgs; [zsh];

    sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
    };

    variables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
    };

    # Selection of sysadmin tools that can come in handy
    systemPackages = with pkgs; [
      dosfstools
      gptfdisk
      iputils
      usbutils
      utillinux
      curl
      gcc
      git
      hddtemp
      jq
      lm_sensors
      lz4
      ntfs3g
      nvme-cli
      p7zip
      pciutils
      unrar
      unzip
      wget
      zip
    ];

    # loginShellInit = ''
    #   dbus-update-activation-environment --systemd DISPLAY
    #   eval $(gnome-keyring-daemon --start --daemonize --components=ssh)
    #   eval $(ssh-agent)
    # '';

    shellAliases = let
      ifSudo = lib.mkIf config.security.sudo.enable;
    in {
      # nix
      nrb = ifSudo "sudo nixos-rebuild";

      # fix nixos-option for flake compat
      nixos-option = "nixos-option -I nixpkgs=${self}/lib/compat";

      # systemd
      ctl = "systemctl";
      stl = ifSudo "s systemctl";
      utl = "systemctl --user";
      ut = "systemctl --user start";
      un = "systemctl --user stop";
      up = ifSudo "s systemctl start";
      dn = ifSudo "s systemctl stop";
      jtl = "journalctl";
    };
  };

  programs.bash = {
    # Enable starship
    promptInit = "";

    # Enable direnv, a tool for managing shell environments
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    '';
  };

  # For rage encryption, all hosts need a ssh key pair
  services.openssh = {
    enable = true;
    openFirewall = true;
    ports = [22];

    settings = {
      X11Forwarding = false;
      PermitRootLogin = lib.mkForce "no";
      UseDns = false;
      PasswordAuthentication = lib.mkForce false;
      KbdInteractiveAuthentication = false;
    };

    hostKeys = [
      {
        bits = 4096;
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  programs.ssh.startAgent = true;

  # Service that makes Out of Memory Killer more effective
  services.earlyoom.enable = true;

  programs = {
    dconf.enable = true;
    nm-applet.enable = true;
    seahorse.enable = true;

    npm = {
      enable = true;
      npmrc = ''
        prefix = ''${HOME}/.npm
        color = true
      '';
    };
  };

  services = {
    blueman.enable = false;
    fwupd.enable = true;
    gvfs.enable = true;
    lorri.enable = true;
    udisks2.enable = true;
    printing.enable = true;
    fstrim.enable = true;
    v2raya.enable = true;

    udev.packages = with pkgs; [gnome.gnome-settings-daemon];

    dbus = {
      enable = true;
      packages = with pkgs; [dconf gcr];
    };

    gnome = {
      glib-networking.enable = true;
      gnome-keyring.enable = true;
    };

    pipewire = {
      enable = true;
      wireplumber.enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
    };

    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "lock";
      extraConfig = ''
        HandlePowerKey=suspend-then-hibernate
        HibernateDelaySec=3600
      '';
    };
  };

  systemd.user.services = {
    pipewire.wantedBy = ["default.target"];
    pipewire-pulse.wantedBy = ["default.target"];
  };

  security = {
    rtkit.enable = true;

    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
      packages = [pkgs.apparmor-profiles];
    };

    pam = {
      services.login.enableGnomeKeyring = true;

      loginLimits = [
        {
          domain = "@wheel";
          item = "nofile";
          type = "soft";
          value = "524288";
        }
        {
          domain = "@wheel";
          item = "nofile";
          type = "hard";
          value = "1048576";
        }
      ];
    };
  };
}

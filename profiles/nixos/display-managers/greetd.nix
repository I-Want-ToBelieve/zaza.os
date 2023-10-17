{ inputs, pkgs, ... }: {
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "Hyprland";
        user = "i.want.to.believe";
      };
      default_session = initial_session;
    };
  };

  # selectable options
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
  # add hyprland to display manager sessions
  services.xserver.displayManager.sessionPackages =
    [ inputs.hyprland.packages.${pkgs.system}.default ];

  security = {
    pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
  };

  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
      WLR_BACKEND = "vulkan";
      GDK_BACKEND = "wayland";
    };
  };
}

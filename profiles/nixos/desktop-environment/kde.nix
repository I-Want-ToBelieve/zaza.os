{ pkgs, ... }: {
  services.xserver.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # @see https://github.com/NixOS/nixpkgs/issues/75867#issuecomment-949542936
  programs.ssh.askPassword =
    pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";

  # @see https://github.com/Prayag2/kde_controlcentre/issues/6#issuecomment-1271939571 libsForQt5.kdeplasma-addons
  environment.systemPackages = with pkgs; [
    libsForQt5.kdeplasma-addons
    libsForQt5.qt5.qtwebsockets
    libsForQt5.qt5.qtwebchannel
    (python3Full.withPackages (ps:
      with ps;
      [
        websockets
        # other python packages
      ]))
    (wallpaper-engine-kde-plugin.overrideAttrs (finalAttrs: previousAttrs: {
      patches = (previousAttrs.patches or [ ]) ++ [
        (fetchpatch {
          name = "wallpaper-engine-kde-plugin-main-nixos.patch";
          url =
            "https://github.com/I-Want-ToBelieve/wallpaper-engine-kde-plugin/commit/95bb3268d7576473a61416f75c38fe93047a11a5.patch";
          sha256 = "sha256-FBoJEX8nZNt5Wy/10nzv5DcMNL8xoxDPHyfJJleoGUM=";
        })
      ];
    }))

    plasma5-applets-window-appmenu
    lightly-shaders
  ];

  programs.kdeconnect = { enable = true; };
}

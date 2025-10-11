{pkgs, ...}: {
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
  ];

  programs.kdeconnect = {enable = true;};
}

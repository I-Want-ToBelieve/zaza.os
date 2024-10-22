{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      # chromium
      hyprwayland-scanner
      hyprutils
      hyprland-protocols
    ];
  };
}

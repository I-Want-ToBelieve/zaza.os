{pkgs, ...}: {
  services = {
    desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = false;
    };
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };
  security.rtkit.enable = true;

  # 保留 Plasma 本体、系统设置和 Dolphin；用户应用由主机单独选择。
  # PIM 默认会启用 Akonadi；单靠 excludePackages 不能关闭它。
  programs.kde-pim.enable = false;
  environment.plasma6 = {
    excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      plasma-workspace-wallpapers
      konsole
      kwin-x11
      ark
      elisa
      gwenview
      okular
      kate
      ktexteditor
      khelpcenter
      baloo-widgets
      dolphin-plugins
      spectacle
      ffmpegthumbs
      krdp
      plasma-keyboard
      qtvirtualkeyboard
      union
      qrca
      discover
    ];
  };
}

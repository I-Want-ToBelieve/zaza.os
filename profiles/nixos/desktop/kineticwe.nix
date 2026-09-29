# Stellar 的平台无关会话。显卡后端与自动登录由开发 VM 自己选择。
{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.kineticwe.nixosModules.default];

  programs.kineticwe.enable = true;
  hardware.graphics.enable = true;
  services.upower.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # 上游启动脚本会启动这个 target，但锁定的 Nix 包没有安装它。
  systemd.user.targets.kineticwe-workspace = {
    description = "KineticWE graphical workspace";
    requires = ["graphical-session.target"];
    bindsTo = ["graphical-session.target"];
    wants = ["graphical-session-pre.target" "xdg-desktop-autostart.target"];
    after = ["graphical-session-pre.target"];
    before = ["graphical-session.target" "xdg-desktop-autostart.target"];
  };

  environment.systemPackages = with pkgs; [
    foot
    wl-clipboard
    libnotify
    kdePackages.kscreen # kscreen-doctor 使用 KWin 的输出管理接口。
    kdePackages.spectacle
    kdePackages.kate # AppMenu 的 Qt/Wayland 验证应用。
  ];
}

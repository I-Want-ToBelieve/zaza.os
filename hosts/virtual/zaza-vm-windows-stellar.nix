# WHPX 图形开发副本；独立 hostname、磁盘和 Home Manager 配置。
{
  lib,
  pkgs,
  ...
}: {
  imports = [./zaza-vm-windows.nix];

  # QEMU 非 GL virtio-vga：KWin 使用 QPainter，原生 Noctalia 使用 Mesa 软件 EGL。
  environment.sessionVariables = {
    KWIN_COMPOSE = "Q";
    LIBGL_ALWAYS_SOFTWARE = "1";
  };
  fonts.packages = with pkgs; [inter noto-fonts noto-fonts-color-emoji];

  services.greetd = {
    enable = true;
    settings = let
      session = {
        command = toString (pkgs.writeShellScript "stellar-session" ''
          trap '${pkgs.systemd}/bin/systemctl --user stop kineticwe-workspace.target graphical-session.target' EXIT
          ${pkgs.kineticwe}/bin/start-kineticwe
        '');
        user = "i.want.to.believe";
      };
    in {
      initial_session = session;
      default_session = session;
    };
  };

  # C++ 首次构建限制并行度，避免 12 GiB guest 内存耗尽。
  nix.settings = {
    max-jobs = lib.mkForce 1;
    cores = lib.mkForce 4;
  };
}

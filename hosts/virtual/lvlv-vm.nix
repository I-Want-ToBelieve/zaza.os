{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./zaza-vm-windows.nix
    ../nixos/lvlv/common.nix
  ];

  # 默认让 KWin/Mesa 使用 virtio-vga-gl 的 VirGL；不强制软件合成。
  # 非 GL/VNC 恢复入口保留原先的 QPainter 设置。
  specialisation.software-rendering.configuration = {
    environment.sessionVariables = {
      KWIN_COMPOSE = "Q";
      LIBGL_ALWAYS_SOFTWARE = "1";
    };
    services.displayManager.sddm.settings.General.GreeterEnvironment =
      lib.mkForce "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,KWIN_COMPOSE=Q,LIBGL_ALWAYS_SOFTWARE=1";
  };
  environment.systemPackages = [pkgs.mesa-demos];
  # TCG 首次加载 Qt/桌面会超过上游启动动画的 40 秒超时。
  systemd.user.services.plasma-ksplash = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutSec = "5min";
  };
  home-manager.users."i.want.to.believe" = {
    config,
    pkgs,
    ...
  }: let
    # qdbus 的接口探测在 TCG 首次登录时仍会超时；布局脚本使用已知接口直接调用。
    plasmaCall = ''
      qdbus() {
        if [ "$3" = org.kde.PlasmaShell.evaluateScript ]; then
          ${pkgs.systemd}/bin/busctl --user --timeout=120s call \
            "$1" "$2" org.kde.PlasmaShell evaluateScript s "$4" >/dev/null
        else
          command qdbus "$@"
        fi
      }
    '';
  in {
    programs.plasma = {
      startup.desktopScript = {
        panels.preCommands = lib.mkForce (plasmaCall
          + ''
            # 保留锁定版 plasma-manager 的清理行为（上游 issue #76）。
            rm -f "${config.xdg.configHome}/plasma-org.kde.plasma.desktop-appletsrc"
          '');
        wallpaper_picture.preCommands = plasmaCall;
      };
      # TCG 下首次载入主题较慢，等待桌面就绪后再由 plasma-manager 创建面板。
      startup.startupScript.wait_for_desktop = {
        priority = 1;
        runAlways = true;
        text = ''
          ready=0
          for attempt in $(seq 1 30); do
            if ${pkgs.systemd}/bin/busctl --user --timeout=10s call \
              org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s \
              'print(desktops().length > 0 ? "ready" : "waiting")' \
              | ${pkgs.gnugrep}/bin/grep -q ready; then
              ready=1
              break
            fi
            sleep 2
          done
          if [ "$ready" != 1 ]; then
            echo "Plasma desktop was not ready; layout remains pending for next login." >&2
            exit 1
          fi
        '';
      };
      # 仅验证 VM 保持显示，便于长时间构建后通过 VNC 检查桌面。
      powerdevil.AC = {
        autoSuspend.action = "nothing";
        turnOffDisplay.idleTimeout = "never";
        dimDisplay.enable = false;
      };
    };
  };
  services.displayManager = {
    sddm.settings.General.GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
    autoLogin = {
      enable = true;
      user = "i.want.to.believe";
    };
  };
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };
  nix.settings = {
    max-jobs = lib.mkForce 1;
    cores = lib.mkForce 4;
  };
}

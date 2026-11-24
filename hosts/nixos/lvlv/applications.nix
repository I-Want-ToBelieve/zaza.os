# 用户确认的 GUI 名单；只由 lvlv.os 与其 QEMU 验证机导入。
{pkgs, ...}: {
  programs = {
    firefox = {
      enable = true;
      # Wayland 下显式请求系统装饰，避免 GTK 自绘灰色标题栏按钮。
      package = pkgs.firefox.overrideAttrs (old: {
        makeWrapperArgs = old.makeWrapperArgs ++ ["--set" "MOZ_GTK_TITLEBAR_DECORATION" "system"];
      });
      # 使用 KWin 的标题栏与窗口装饰；覆盖已有 profile 的自绘标题栏设置。
      policies.Preferences."browser.tabs.inTitlebar" = {
        Value = 0;
        Status = "user";
        Type = "number";
      };
    };
    obs-studio.enable = true;
    localsend = {
      enable = true;
      openFirewall = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      vicinae
      kitty
      vscode
      copyq
      flameshot
    ];
    sessionVariables = {
      TERMINAL = "kitty";
      NIXOS_OZONE_WL = "1";
    };
    # 系统默认值仍可由用户设置覆盖；Dolphin 由 Plasma 模块提供。
    etc."xdg/kdeglobals".text = ''
      [General]
      BrowserApplication=firefox.desktop
      TerminalApplication=kitty
      TerminalService=kitty.desktop
    '';
  };

  # 只合并标题栏设置，保留可写的用户文件；不导入大型 VS Code 套件。
  home-manager.users."i.want.to.believe" = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.activation.vscodeNativeTitlebar = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.python3.withPackages (ps: [ps.json5])}/bin/python - ${lib.escapeShellArg "${config.xdg.configHome}/Code/User/settings.json"} <<'PY'
      import json
      import os
      from pathlib import Path
      import stat
      import sys
      import tempfile
      import json5

      path = Path(sys.argv[1])
      if path.is_symlink():
          raise SystemExit("VS Code settings are a symlink; refusing to replace them.")
      original = path.read_bytes() if path.exists() else None
      settings = json5.loads(original.decode("utf-8-sig")) if original else {}
      if not isinstance(settings, dict):
          raise SystemExit("VS Code settings must be a JSON object.")
      desired = {
          "window.titleBarStyle": "native",
          "window.customTitleBarVisibility": "never",
      }
      if all(settings.get(key) == value for key, value in desired.items()):
          sys.exit(0)
      settings.update(desired)
      path.parent.mkdir(parents=True, exist_ok=True)
      if original is not None:
          backup = path.with_name("settings.json.before-kde-titlebar")
          if not backup.exists():
              backup.write_bytes(original)
              backup.chmod(0o600)
      mode = stat.S_IMODE(path.stat().st_mode) if original is not None else 0o600
      fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".settings-")
      try:
          with os.fdopen(fd, "w", encoding="utf-8") as output:
              output.write(json.dumps(settings, ensure_ascii=False, indent=2) + "\n")
          os.chmod(temporary, mode)
          os.replace(temporary, path)
      finally:
          if os.path.exists(temporary):
              os.unlink(temporary)
      PY
    '';
  };

  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "inode/directory" = "org.kde.dolphin.desktop";
    };
  };

  # 使用包自带服务，保留其命令、重载与退出语义。
  systemd = {
    packages = [pkgs.vicinae];
    user.services = {
      vicinae = {
        overrideStrategy = "asDropin";
        wantedBy = ["graphical-session.target"];
        unitConfig.ConditionUser = "i.want.to.believe";
      };
      copyq = {
        description = "CopyQ clipboard manager";
        wantedBy = ["graphical-session.target"];
        after = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        unitConfig.ConditionUser = "i.want.to.believe";
        serviceConfig = {
          ExecStart = "${pkgs.copyq}/bin/copyq";
          Environment = "QT_QPA_PLATFORM=wayland";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
  };
}

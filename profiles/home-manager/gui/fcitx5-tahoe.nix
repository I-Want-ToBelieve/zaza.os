{
  config,
  pkgs,
  ...
}: let
  theme = pkgs.callPackage ../../../pkgs/fcitx5-tahoe {};
  rimeYaml = pkgs.formats.yaml {};
  reloadFcitx = pkgs.writeShellScript "reload-fcitx5-tahoe" ''
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    if [ -S "$XDG_RUNTIME_DIR/bus" ] && \
      ${pkgs.systemd}/bin/busctl --user --timeout=2s call \
        org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 State >/dev/null 2>&1; then
      ${pkgs.fcitx5}/bin/fcitx5-remote -r
      ${pkgs.systemd}/bin/busctl --user call \
        org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui
    fi
  '';
in {
  # 仅 lvlv 用户导入；不改已有主机的 fcitx5 / Catppuccin 配置。
  xdg.dataFile = {
    "fcitx5/themes/Tahoe-Light".source = "${theme}/share/fcitx5/themes/Tahoe-Light";
    "fcitx5/themes/Tahoe-Dark".source = "${theme}/share/fcitx5/themes/Tahoe-Dark";
    # 只声明配置，Rime 的 build、userdb 与用户词频保持可写。
    "fcitx5/rime/default.custom.yaml" = {
      source = rimeYaml.generate "tahoe-rime-default.custom.yaml" {
        customization = {
          generator = "Home Manager";
          rime_version = pkgs.librime.version;
        };
        patch = {
          "__include" = "rime_ice_suggestion:/";
          schema_list = [{schema = "rime_ice";}];
          "menu/page_size" = 9;
          "menu/alternative_select_labels" = ["1 " "2 " "3 " "4 " "5 " "6 " "7 " "8 " "9 "];
          "switcher/hotkeys" = ["F4"];
          "ascii_composer/good_old_caps_lock" = false;
          "ascii_composer/switch_key" = {
            Caps_Lock = "noop";
            Shift_L = "noop";
            Shift_R = "noop";
            Control_L = "noop";
            Control_R = "noop";
          };
        };
      };
      # Nix store 文件时间为零；Rime 不能据此发现新配置。只清理可再生成的
      # 两个配置缓存，保留词典二进制、userdb 和用户词频。
      onChange = ''
        run ${pkgs.coreutils}/bin/rm -f \
          "${config.xdg.dataHome}/fcitx5/rime/build/default.yaml" \
          "${config.xdg.dataHome}/fcitx5/rime/build/rime_ice.schema.yaml"
        run ${reloadFcitx}
        runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        if [ -S "$runtime_dir/bus" ] && \
          XDG_RUNTIME_DIR="$runtime_dir" DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
          ${pkgs.systemd}/bin/busctl --user --timeout=2s call \
            org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 State >/dev/null 2>&1; then
          run env XDG_RUNTIME_DIR="$runtime_dir" DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
            ${pkgs.systemd}/bin/busctl --user call \
            org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 SetConfig sv \
            fcitx://config/addon/rime/deploy a{sv} 0
        fi
      '';
    };
  };
  xdg.configFile = {
    "fcitx5/profile".text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=rime

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [GroupOrder]
      0=Default
    '';
    "fcitx5/config" = {
      onChange = ''run ${reloadFcitx}'';
      text = ''
        [Hotkey]
        EnumerateWithTriggerKeys=False
        AltTriggerKeys=
        EnumerateGroupForwardKeys=
        EnumerateGroupBackwardKeys=

        [Hotkey/TriggerKeys]
        0=Control+space

        [Behavior]
        ActiveByDefault=True
        ShareInputState=No
        PreeditEnabledByDefault=True
        ShowInputMethodInformation=True
        showInputMethodInformationWhenFocusIn=False
        CompactInputMethodInformation=True
        DefaultPageSize=9
      '';
    };
    "fcitx5/conf/classicui.conf".text = ''
      TahoeCandidateGrid=True
      TahoeAnimations=True
      Vertical Candidate List=False
      WheelForPaging=True
      Font="Noto Sans CJK SC 12"
      MenuFont="Noto Sans CJK SC 11"
      TrayFont="Noto Sans CJK SC 10"
      PreferTextIcon=True
      ShowLayoutNameInIcon=False
      UseInputMethodLanguageToDisplayText=True
      Theme=Tahoe-Light
      DarkTheme=Tahoe-Dark
      UseDarkTheme=True
      UseAccentColor=False
      PerScreenDPI=True
      ForceWaylandDPI=0
      EnableFractionalScale=True
    '';
    "fcitx5/conf/rime.conf".text = ''
      PreeditMode=No
      SwitchInputMethodBehavior=CommitCommitPreview
    '';
  };
}

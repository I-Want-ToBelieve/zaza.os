{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
    ];

    sessionVariables = {
      # XDG Specifications
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";

      # QT Variables

      # Toolkit Backend Variables
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      CLUTTER_BACKEND = "wayland";
      GDK_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
    };
  };

  wayland.windowManager.hyprland = {
    # Whether to enable Hyprland wayland compositor
    enable = true;
    # The hyprland package to use
    package = pkgs.hyprland;
    # Whether to enable XWayland
    xwayland.enable = true;
    # Optional
    # Whether to enable hyprland-session.target on hyprland startup
    systemd.enable = true;

    plugins = [
      pkgs.hyprlandPlugins.hyprexpo
      # inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
    ];

    settings = {
      "$mod" = "SUPER";
      exec-once = [
        # "${pkgs.hyprpanel}/bin/hyprpanel"
        "copyq &"
        "fcitx5 -d"
        "${pkgs.hyprpanel}/bin/hyprpanel"
      ];

      monitor = ",preferred,auto,2";

      general = {
        layout = "master";
      };

      master = {
      };

      plugins = {
        hyprexpo = {
          columns = 7;
          gap_size = 5;
          bg_col = "rgb(111111)";
          workspace_method = "center current"; # [center/first] [workspace] e.g. first 1 or center m+1

          enable_gesture = true; # laptop touchpad
          gesture_fingers = 3; # 3 or 4
          gesture_distance = 300; # how far is the "max"
          gesture_positive = true; # positive = swipe down. Negative = swipe up.
        };
      };

      input = {
        kb_options = "caps:swapescape";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = "no";
        };
      };

      windowrulev2 = [
        "float,class:^com.github.hluk.copyq$"
      ];

      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];

      bindd = [
        "SUPER, code:36, open terminal by super enter, exec, kitty"
      ];

      bind = [
        # "$mod, W, overview:toggle,"
        "$mod, G, hyprexpo:expo, toggle"
        "$mod, Q, killactive, "
        "$mod, M, exec, wlogout --protocol layer-shell"
        "$mod, E, exec, thunar"
        "Control_L, G, exec, copyq toggle"
        "$mod, V, togglefloating, "
        "$mod, D, exec, wofi --show drun"
        "$mod, P, pseudo, # dwindle"
        "$mod, S, togglesplit, # dwindle"
        "$mod SHIFT, Q, exec, swaylock"
        ",PRINT, exec, hyprshot -m region --clipboard-only"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod CTRL, l, resizeactive, 10 0"
        "$mod CTRL, h, resizeactive, -10 0"
        "$mod CTRL, k, resizeactive, 0 -10"
        "$mod CTRL, j, resizeactive, 0 10"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"
      ];
    };
  };

  # services.gammastep = {
  #   enable = true;
  #   provider = "geoclue2";
  # };

  systemd.user.services.swaybg = let
    wallpaper = builtins.fetchurl rec {
      name = "wallpaper-${sha256}.png";
      url = "https://raw.githubusercontent.com/I-Want-ToBelieve/wallpapers/main/catppuccin/cat_leaves.png";
      sha256 = "1894y61nx3p970qzxmqjvslaalbl2skj5sgzvk38xd4qmlmi9s4i";
    };
  in {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg --mode fill --image ${wallpaper}";
      Restart = "on-failure";
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}

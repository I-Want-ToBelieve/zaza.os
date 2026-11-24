{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.appearance.mactahoe;
  themes = pkgs.callPackage ../../../pkgs/mactahoe {
    mactahoeKdeSrc = inputs.mactahoe-kde;
    mactahoeGtkSrc = inputs.mactahoe-gtk;
    mactahoeIconsSrc = inputs.mactahoe-icons;
  };
  color =
    if cfg.kde.enable
    then cfg.kde.color
    else cfg.gtk.color;
  iconTheme = "MacTahoe-${color}";
  uiFont = {
    family = "Inter";
    pointSize = 10;
  };
in {
  # lvlvUsers registers the reusable modules explicitly (standardExtras = false).
  # This profile selects both themes and retains lvlv's desktop layout.
  appearance.mactahoe = {
    kde.enable = lib.mkDefault true;
    gtk.enable = lib.mkDefault true;
  };

  home = {
    packages = [themes.icons pkgs.inter pkgs.jetbrains-mono];
    pointerCursor = {
      enable = true;
      package = themes.icons;
      name = iconTheme;
      size = 24;
      gtk.enable = cfg.gtk.enable;
    };
  };
  fonts.fontconfig.enable = true;
  gtk = lib.mkIf cfg.gtk.enable {
    font = {
      name = "Inter";
      size = 10;
    };
    iconTheme = {
      package = themes.icons;
      name = "MacTahoe-${cfg.gtk.color}";
    };
  };
  xdg.configFile = {
    "kitty/kitty.conf".text = ''
      font_family JetBrainsMono Nerd Font
      font_size 11
      background #f5f5f7
      foreground #242424
      cursor #007aff
      selection_background #c9e2ff
      selection_foreground #242424
      window_padding_width 8
      enable_audio_bell no
    '';
  };

  programs.plasma = lib.mkIf cfg.kde.enable {
    workspace = {
      inherit iconTheme;
      cursor = {
        theme = iconTheme;
        size = 24;
      };
      clickItemTo = "select";
    };
    fonts = {
      general = uiFont;
      menu = uiFont;
      toolbar = uiFont;
      small = uiFont // {pointSize = 9;};
      windowTitle = uiFont // {weight = "demiBold";};
      fixedWidth = {
        family = "JetBrains Mono";
        pointSize = 10;
      };
    };
    kwin = {
      titlebarButtons = {
        left = ["close" "minimize" "maximize"];
        right = [];
      };
      effects.blur = {
        enable = true;
        strength = 5;
        noiseStrength = 2;
      };
    };
    panels = [
      {
        location = "top";
        height = 32;
        lengthMode = "fill";
        floating = false;
        hiding = "none";
        opacity = "translucent";
        widgets = [
          {
            kickoff = {
              icon = "start-here-kde";
              sortAlphabetically = true;
            };
          }
          "org.kde.plasma.appmenu"
          "org.kde.plasma.panelspacer"
          "org.kde.plasma.systemtray"
          {
            digitalClock = {
              date = {
                enable = true;
                format.custom = "ddd MMM d";
                position = "besideTime";
              };
              time.format = "24h";
            };
          }
        ];
      }
      {
        location = "bottom";
        height = 64;
        alignment = "center";
        lengthMode = "fit";
        floating = true;
        hiding = "dodgewindows";
        opacity = "translucent";
        widgets = [
          {
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:firefox.desktop"
                "applications:kitty.desktop"
                "applications:code.desktop"
                "applications:com.obsproject.Studio.desktop"
                "applications:vicinae.desktop"
              ];
              appearance = {
                fill = false;
                iconSpacing = "medium";
              };
            };
          }
        ];
      }
    ];
    configFile = {
      kdeglobals.General.AccentColor = "10,132,255";
      kwinrc."org.kde.kdecoration2".BorderSize = "None";
      dolphinrc.General.ShowFullPath = false;
    };
  };
}

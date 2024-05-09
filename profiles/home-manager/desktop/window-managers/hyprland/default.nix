{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # use OCR and copy to clipboard
  ocrScript = let
    inherit (pkgs) grim libnotify slurp tesseract5 wl-clipboard;
  in
    pkgs.writeShellScriptBin "wl-ocr" ''
      ${grim}/bin/grim -g "$(${slurp}/bin/slurp)" -t ppm - | ${tesseract5}/bin/tesseract5 - - | ${wl-clipboard}/bin/wl-copy
      ${lib.getExe libnotify} "$(${wl-clipboard}/bin/wl-paste)"
    '';
in {
  home = {
    packages = with pkgs; [
      clipman
      grim
      ocrScript
      pngquant
      python3Full.requests
      python3Full.websockets
      slurp
      swayidle
      tesseract5
      wf-recorder
      wl-clipboard
      geoclue2
      xorg.xprop
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
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
    enable = true;
    systemdIntegration = true;
    extraConfig = import ./config.nix;
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

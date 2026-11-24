{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.appearance.mactahoe.gtk;
  package = pkgs.callPackage ../../pkgs/mactahoe/gtk.nix {
    mactahoeGtkSrc = inputs.mactahoe-gtk;
  };
  color =
    if cfg.color == "dark"
    then "Dark"
    else "Light";
  theme = {
    inherit package;
    name = "MacTahoe-${color}${lib.optionalString (cfg.opacity == "solid") "-solid"}";
  };
in {
  options.appearance.mactahoe.gtk = {
    enable = lib.mkEnableOption "the MacTahoe GTK application theme";
    color = lib.mkOption {
      type = lib.types.enum ["light" "dark"];
      default = "light";
      description = "MacTahoe GTK color variant.";
    };
    opacity = lib.mkOption {
      type = lib.types.enum ["normal" "solid"];
      default = "solid";
      description = "GTK opacity variant; solid works without compositor blur rules.";
    };
    libadwaita.enable = lib.mkEnableOption "MacTahoe user CSS for GTK4/libadwaita applications";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      # KDE's GTK bridge rewrites gtkrc at login; Home Manager owns its contents.
      gtk2.force = true;
      inherit theme;
      colorScheme = cfg.color;
      # The pinned HM module imports GTK4 theme CSS when this is non-null.
      gtk4.theme =
        if cfg.libadwaita.enable
        then theme
        else null;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = cfg.color == "dark";
      gtk4.extraConfig.gtk-application-prefer-dark-theme = cfg.color == "dark";
    };
  };
}

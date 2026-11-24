{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.appearance.mactahoe.kde;
  package = pkgs.callPackage ../../pkgs/mactahoe/kde.nix {
    mactahoeKdeSrc = inputs.mactahoe-kde;
  };
  color =
    if cfg.color == "dark"
    then "Dark"
    else "Light";
in {
  imports = [inputs.plasma-manager.homeModules.plasma-manager];

  options.appearance.mactahoe.kde = {
    enable = lib.mkEnableOption "the MacTahoe Plasma, Aurorae and Kvantum themes";
    color = lib.mkOption {
      type = lib.types.enum ["light" "dark"];
      default = "light";
      description = "MacTahoe Plasma color variant.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [package pkgs.kdePackages.qtstyleplugin-kvantum];
    xdg.configFile = {
      "Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=MacTahoe${lib.optionalString (cfg.color == "dark") "Dark"}
      '';
      "Kvantum/MacTahoe".source = "${package}/share/Kvantum/MacTahoe";
    };
    programs.plasma = {
      enable = true;
      overrideConfig = lib.mkDefault false;
      workspace = {
        theme = "MacTahoe-${color}";
        colorScheme = "MacTahoe${color}";
        widgetStyle = "kvantum";
        wallpaper = lib.mkDefault "${package}/share/wallpapers/MacTahoe-${color}/contents/images/3840x2160.jpeg";
        windowDecorations = {
          library = "org.kde.kwin.aurorae";
          theme = "__aurorae__svg__MacTahoe-${color}";
        };
      };
    };
  };
}

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.krohnkite;
in {
  imports = [inputs.plasma-manager.homeModules.plasma-manager];

  options.programs.krohnkite = {
    enable = lib.mkEnableOption "the Krohnkite dynamic tiling script for Plasma 6";
    package = lib.mkPackageOption pkgs ["kdePackages" "krohnkite"] {};
    settings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.oneOf [lib.types.bool lib.types.int lib.types.float lib.types.str]);
      default = {};
      example = {screenGapBetween = 8;};
      description = ''
        Upstream configuration keys written to kwinrc's Script-krohnkite group.
        Unspecified keys use Krohnkite's defaults. After configuration changes,
        call org.kde.KWin.reconfigure on /KWin to reparse kwinrc. Replacing the
        script package requires a fresh Plasma session.
      '';
    };
    shortcuts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
      default = {};
      example = {KrohnkiteToggleFloat = "Meta+F";};
      description = ''
        Krohnkite action names and key sequences managed in the kwin shortcut
        group. An empty string unbinds an action. Unspecified actions retain
        their upstream or existing shortcuts.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
    # 显式提供脚本搜索路径，既适用于 NixOS，也适用于独立 Home Manager。
    xdg.dataFile."kwin/scripts/krohnkite".source = "${cfg.package}/share/kwin/scripts/krohnkite";
    programs.plasma = {
      enable = true;
      overrideConfig = lib.mkDefault false;
      configFile.kwinrc = {
        Plugins.krohnkiteEnabled = true;
        Script-krohnkite = cfg.settings;
      };
      shortcuts.kwin = cfg.shortcuts;
    };
  };
}

{ config, lib, ... }:
let
  cfg = config.services.swhkd;

  keybindingsStr = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (hotkey: command:
      lib.optionalString (command != null) ''
        ${hotkey}
          ${command}
      '') cfg.keybindings);
in {
  options = {
    services.swhkd = {
      enable = lib.mkEnableOption "swhkd hotkey daemon";

      keybindings = lib.mkOption {
        type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
        default = { };
        description = "An attribute set that assigns hotkeys to commands.";
        example = lib.literalExpression ''
          {
            "super + shift + {r,c}" = "i3-msg {restart,reload}";
            "super + {s,w}"         = "i3-msg {stacking,tabbed}";
          }
        '';
      };

      extraConfig = lib.mkOption {
        default = "";
        type = lib.types.lines;
        description = "Additional configuration to add.";
        example = lib.literalExpression ''
          super + {_,shift +} {1-9,0}
            i3-msg {workspace,move container to workspace} {1-10}
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."swhkd/swhkdrc".text =
      lib.concatStringsSep "\n" [ keybindingsStr cfg.extraConfig ];
  };
}

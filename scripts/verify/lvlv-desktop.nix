# nix eval --impure --json --file scripts/verify/lvlv-desktop.nix
let
  flake = builtins.getFlake (toString ../..);
  inherit (flake.nixosConfigurations.lvlv-vm.pkgs) lib;
  normalize = key:
    lib.concatStringsSep "+" (builtins.sort builtins.lessThan
      (map (part:
        if part == "control"
        then "ctrl"
        else part)
      (lib.splitString "+" (lib.toLower key))));
  asList = value:
    if builtins.isList value
    then value
    else lib.optional (value != "") value;
  host = name: let
    pkgs = flake.nixosConfigurations.${name}.pkgs;
    cfg = flake.nixosConfigurations.${name}.config;
    home = cfg.home-manager.users."i.want.to.believe";
    commands = home.programs.plasma.hotkeys.commands;
    shortcutGroups = home.programs.plasma.shortcuts;
    bindings =
      lib.concatMap (command: command.keys ++ lib.optional (command.key != "") command.key)
      (builtins.attrValues commands)
      ++ lib.concatMap (group: lib.concatMap asList (builtins.attrValues group))
      (builtins.attrValues shortcutGroups);
    normalized = map normalize bindings ++ [normalize "Ctrl+Space"];
  in
    assert builtins.length normalized == builtins.length (lib.unique normalized);
    assert commands.launch-vicinae.key == "Meta+Space";
    assert commands.launch-kitty.key == "Meta+Return";
    assert commands.toggle-kitty-quick-access.key == "Ctrl+T";
    assert commands.toggle-kitty-quick-access.command == "${pkgs.kitty}/bin/kitten quick-access-terminal --detach";
    assert commands.toggle-copyq.key == "Meta+V";
    assert commands.capture-flameshot.keys == ["Print" "Meta+Shift+S"];
    assert shortcutGroups.klipper.show-klipper-popupmenu == [];
    assert shortcutGroups.plasmashell.show-on-mouse-pos == [];
    assert shortcutGroups.plasmashell.cycle-panels == [];
    assert shortcutGroups."KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" == [];
    assert shortcutGroups.kwin."Switch One Desktop to the Left" == [];
    assert shortcutGroups."org.kde.spectacle.desktop"._launch == [];
    assert cfg.i18n.inputMethod.fcitx5.waylandFrontend;
    assert lib.hasInfix "TahoeCandidateGrid=True" home.xdg.configFile."fcitx5/conf/classicui.conf".text;
    assert lib.hasInfix "UseDarkTheme=True" home.xdg.configFile."fcitx5/conf/classicui.conf".text; {
      inherit bindings;
      quickAccessConfig = home.xdg.configFile."kitty/quick-access-terminal.conf".text;
      inputMethodPackage = cfg.i18n.inputMethod.package.outPath;
      theme = home.appearance.mactahoe;
      tiling = home.programs.krohnkite.enable;
      terminal = cfg.environment.sessionVariables.TERMINAL;
    };
  physical = host "lvlv.os";
  vm = host "lvlv-vm";
in
  assert physical.bindings == vm.bindings;
  assert physical.quickAccessConfig == vm.quickAccessConfig;
  assert physical.inputMethodPackage == vm.inputMethodPackage; {
    inherit physical vm;
  }

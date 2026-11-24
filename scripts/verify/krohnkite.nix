# nix eval --impure --json --file scripts/verify/krohnkite.nix
let
  flake = builtins.getFlake (toString ../..);
  pkgs = flake.nixosConfigurations.lvlv-vm.pkgs;
  inherit (pkgs) lib;
  inactive = withModule:
    (flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs.inputs = flake.inputs;
      modules =
        [
          flake.inputs.plasma-manager.homeModules.plasma-manager
          {
            home = {
              username = "inactive-test";
              homeDirectory = "/home/inactive-test";
              stateVersion = "26.05";
            };
          }
        ]
        ++ lib.optional withModule flake.homeManagerModules.krohnkite;
    }).activationPackage.drvPath;
  check = modules: let
    home = flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs.inputs = flake.inputs;
      modules =
        [
          flake.homeManagerModules.krohnkite
          {
            home = {
              username = "tiling-test";
              homeDirectory = "/home/tiling-test";
              stateVersion = "26.05";
            };
          }
        ]
        ++ modules;
    };
    cfg = home.config;
    enabled = cfg.programs.krohnkite.enable;
    packages = map (package: package.pname or package.name) cfg.home.packages;
  in
    assert lib.elem (cfg.programs.krohnkite.package.pname or cfg.programs.krohnkite.package.name) packages == enabled;
    assert builtins.hasAttr "kwin/scripts/krohnkite" cfg.xdg.dataFile == enabled;
    assert cfg.programs.plasma.enable == enabled;
    assert !enabled || cfg.programs.plasma.configFile.kwinrc.Plugins.krohnkiteEnabled.value;
    assert enabled || !(builtins.hasAttr "kwinrc" cfg.programs.plasma.configFile); {
      inherit enabled packages;
      settings = cfg.programs.krohnkite.settings;
      shortcuts = cfg.programs.krohnkite.shortcuts;
    };
  profile = flake.profiles.home-manager.desktop.krohnkite;
  defaults = check [];
  selected = check [profile];
  bindings = lib.filter (key: key != "") (builtins.attrValues selected.shortcuts);
  metaOnly = key: builtins.match "Meta[+][^+]+" key != null;
  reserved = ["Meta+Space" "Meta+Return" "Meta+L" "Meta+D" "Meta+E" "Meta+V" "Meta+W"];
  disabled = check [profile {programs.krohnkite.enable = false;}];
  custom = check [
    {
      programs.krohnkite = {
        enable = true;
        settings.screenGapBetween = 12;
        shortcuts.KrohnkiteToggleFloat = "";
      };
    }
  ];
  host = name: let
    cfg = flake.nixosConfigurations.${name}.config;
    home = cfg.home-manager.users."i.want.to.believe";
  in
    assert home.programs.krohnkite.enable;
    assert home.programs.krohnkite.settings == selected.settings;
    assert home.programs.krohnkite.shortcuts == selected.shortcuts;
    assert lib.all (key: !(lib.elem key reserved)) bindings;
    assert lib.all (action: home.programs.plasma.shortcuts.kwin.${action} == []) ["Window Quick Tile Left" "Window Quick Tile Bottom" "Window Quick Tile Top" "Window Quick Tile Right" "Edit Tiles"];
    assert lib.all (number: home.programs.plasma.shortcuts.kwin."Switch to Desktop ${toString number}" == "Ctrl+F${toString number}") [1 2 3 4];
    assert home.programs.krohnkite.package.outPath == flake.inputs.krohnkite.packages.${pkgs.stdenv.hostPlatform.system}.krohnkite.outPath; {
      package = home.programs.krohnkite.package.outPath;
      version = home.programs.krohnkite.package.version;
      inherit (home.programs.krohnkite) settings shortcuts;
    };
in
  assert !defaults.enabled;
  assert selected.enabled;
  assert builtins.length (builtins.attrNames selected.shortcuts) == 39;
  assert builtins.length bindings == 25;
  assert builtins.length (lib.unique bindings) == 25;
  assert lib.all metaOnly bindings;
  assert !disabled.enabled;
  assert custom.settings.screenGapBetween == 12;
  assert custom.shortcuts.KrohnkiteToggleFloat == "";
  assert !(builtins.hasAttr "KrohnkiteFocusLeft" custom.shortcuts); {
    inherit defaults selected disabled custom;
    inactive = assert inactive false == inactive true; {
      unchanged = true;
      activationDrv = inactive true;
    };
    physical = host "lvlv.os";
    vm = host "lvlv-vm";
  }

# nix eval --impure --json --file scripts/verify/mactahoe.nix
let
  flake = builtins.getFlake (toString ../..);
  pkgs = flake.nixosConfigurations.lvlv-vm.pkgs;
  inherit (pkgs) lib;
  check = {
    gtk ? false,
    kde ? false,
    color ? "light",
    opacity ? "solid",
    libadwaita ? false,
  }: let
    home = flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs.inputs = flake.inputs;
      modules = [
        flake.homeManagerModules.mactahoe-gtk
        flake.homeManagerModules.mactahoe-kde
        {
          home = {
            username = "theme-test";
            homeDirectory = "/home/theme-test";
            stateVersion = "26.05";
          };
          appearance.mactahoe = {
            gtk = {
              enable = gtk;
              inherit color opacity;
              libadwaita.enable = libadwaita;
            };
            kde = {
              enable = kde;
              inherit color;
            };
          };
        }
      ];
    };
    cfg = home.config;
    packages = map (package: package.pname or package.name) cfg.home.packages;
    variant =
      if color == "dark"
      then "Dark"
      else "Light";
    gtk4Css = builtins.hasAttr "gtk-4.0/gtk.css" cfg.xdg.configFile;
  in
    assert cfg.gtk.enable == gtk;
    assert cfg.programs.plasma.enable == kde;
    assert lib.elem "mactahoe-gtk-theme" packages == gtk;
    assert lib.elem "mactahoe-kde" packages == kde;
    assert gtk4Css == (gtk && libadwaita);
    assert !gtk || cfg.gtk.theme.name == "MacTahoe-${variant}${lib.optionalString (opacity == "solid") "-solid"}";
    assert !kde || cfg.programs.plasma.workspace.theme == "MacTahoe-${variant}";
    assert !kde || cfg.xdg.configFile."Kvantum/kvantum.kvconfig".text == "[General]\ntheme=MacTahoe${lib.optionalString (color == "dark") "Dark"}\n"; {
      inherit packages gtk4Css;
      gtkEnabled = cfg.gtk.enable;
      kdeEnabled = cfg.programs.plasma.enable;
      gtkTheme =
        if gtk
        then cfg.gtk.theme.name
        else null;
      kdeTheme =
        if kde
        then cfg.programs.plasma.workspace.theme
        else null;
      activationDrv = home.activationPackage.drvPath;
    };
in {
  disabled = check {};
  gtkOnly = check {gtk = true;};
  kdeOnly = check {kde = true;};
  bothLight = check {
    gtk = true;
    kde = true;
  };
  bothDark = check {
    gtk = true;
    kde = true;
    color = "dark";
    opacity = "normal";
  };
  gtk4 = check {
    gtk = true;
    libadwaita = true;
  };
}

{
  description = "Krohnkite: modular Effect v4 tiling for KDE Plasma";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    pkgsFor = system: import nixpkgs {inherit system;};
    packageFor = pkgs: pkgs.callPackage ./nix/package.nix {source = self;};
  in {
    packages = forAllSystems (system: let
      krohnkite = packageFor (pkgsFor system);
    in {
      inherit krohnkite;
      default = krohnkite;
    });

    overlays.default = final: _prev: {krohnkite = packageFor final;};

    checks = forAllSystems (system: let
      pkgs = pkgsFor system;
      krohnkite = self.packages.${system}.krohnkite;
    in {
      inherit krohnkite;
      qt-runtime = pkgs.callPackage ./nix/qt-check.nix {inherit krohnkite;};
    });

    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
      toolchain = import ./nix/toolchain.nix {inherit pkgs;};
    in {
      default = pkgs.mkShell {
        packages = [toolchain.nodejs toolchain.pnpm pkgs.git pkgs.alejandra pkgs.patchelf];
        nativeBuildInputs = [pkgs.autoPatchelfHook];
        buildInputs = [pkgs.stdenv.cc.cc.lib];
        shellHook = ''
          export NX_DAEMON=false
          export pnpm_config_pm_on_fail=ignore
          krohnkite-install() {
            pnpm install --frozen-lockfile
            autoPatchelf node_modules
          }
        '';
      };
    });

    formatter = forAllSystems (system: (pkgsFor system).alejandra);
  };
}

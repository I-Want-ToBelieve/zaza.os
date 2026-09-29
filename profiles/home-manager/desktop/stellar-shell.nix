{
  inputs,
  pkgs,
  ...
}: let
  noctalia = inputs.kineticwe.packages.${pkgs.stdenv.hostPlatform.system}.noctalia;
in {
  # Home Manager 自带同名模块；使用与 KineticWE 锁定版本一致的上游契约。
  disabledModules = ["programs/noctalia.nix"];
  imports = [inputs.kineticwe.inputs.noctalia.homeModules.default];

  xdg.enable = true;

  home.packages = [
    (pkgs.writeShellApplication {
      name = "stellar-doctor";
      runtimeInputs = [pkgs.coreutils pkgs.procps pkgs.systemd noctalia];
      # Collect failures so one missing service does not hide the remaining diagnostics.
      bashOptions = ["nounset" "pipefail"];
      text = builtins.readFile ../../../stellar/doctor.sh;
    })
  ];

  programs.noctalia = {
    enable = true;
    # Use the same binary as start-kineticwe, including its pinned dependency set.
    package = noctalia;
    # KineticWE starts and supervises Noctalia as its session child.
    systemd.enable = false;
    validateConfig = true;
    settings = ../../../stellar/noctalia/config.toml;
    customPalettes.Stellar = ../../../stellar/palettes/Stellar.json;
  };
}

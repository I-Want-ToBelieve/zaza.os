{ config, lib, pkgs, ... }:
let cfg = config.services.sunshine;
in {
  options = {
    services.sunshine = { enable = lib.mkEnableOption (lib.mdDoc "Sunshine"); };
  };

  config = lib.mkIf cfg.enable {
    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };

    systemd.user.services.sunshine = {
      description = "sunshine";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = { ExecStart = "${config.security.wrapperDir}/sunshine"; };
    };
  };
}

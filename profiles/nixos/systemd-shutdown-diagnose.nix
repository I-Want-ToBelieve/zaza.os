{ pkgs, ... }: {
  environment = {
    systemPackages = with pkgs; [ inur.systemd-shutdown-diagnose ];
  };

  systemd.services.shutdown-diagnose = {
    description =
      "A service to execute start diagnose-shutdown at begining of shutdown";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "idle";
      RemainAfterExit = "yes";
      ExecStart = "/usr/bin/env true";
      ExecStop =
        "${pkgs.inur.systemd-shutdown-diagnose}/bin/start-diagnose-shutdown";
    };
  };
}

{ pkgs, ... }: {
  # @see uudeck aur
  environment.etc = {
    "uu/uuplugin_monitor.config" = {
      source = ./uuplugin_monitor.config;
      mode = "0755";
    };
    "uu/uuplugin_monitor.sh" = {
      source = ./uuplugin_monitor.sh;
      mode = "0755";
    };
    "uu/uninstall.sh" = {
      source = ./uninstall.sh;
      mode = "0755";
    };
  };

  systemd.services.uuplugin = {
    description = "UU Plugin";
    path = with pkgs; [
      coreutils
      curl
      wget
      gawk
      procps
      iproute2
      gnutar
      gzip
      iptables
    ];
    wants = [ "network-online.target" ];
    after = [ "network.target" "network-online.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = { ExecStart = "/etc/uu/uuplugin_monitor.sh"; };
  };
}

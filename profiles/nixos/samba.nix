{
  pkgs,
  lib,
  ...
}: {
  services.gvfs = {
    enable = true;
    package = lib.mkForce pkgs.gnome3.gvfs;
  };
  services.samba-wsdd.enable =
    true; # make shares visible for windows 10 clients
  networking.firewall.allowedTCPPorts = [
    5357 # wsdd
  ];
  networking.firewall.allowedUDPPorts = [
    3702 # wsdd
  ];

  environment.systemPackages = with pkgs; [cifs-utils];

  fileSystems."/mnt/samba/public" = {
    device = "//192.168.0.121/public";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts}"];
  };

  services.samba = {
    enable = true;
    securityType = "user";
    # extraConfig = ''
    #   workgroup = WORKGROUP
    #   server string = smbnix
    #   netbios name = smbnix
    #   security = user
    #   #use sendfile = yes
    #   #max protocol = smb2
    #   # note: localhost is the ipv6 localhost ::1
    #   hosts allow = 192.168.10. 192.168.31. 192.168.0. 127.0.0.1 localhost
    #   hosts deny = 0.0.0.0/0
    #   guest account = nobody
    #   map to guest = bad user

    #   allow insecure wide links = yes
    # '';

    shares = {
      public = {
        path = "/mnt/share";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "public" = "yes";
        "guest only" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "follow symlinks" = "yes";
        "wide links" = "yes";
      };
    };
  };

  systemd.tmpfiles.rules = [
    # after exec:
    # sudo chmod -R 1777 /mnt/share/
    "d /mnt/share 1777 root root -"
  ];
}

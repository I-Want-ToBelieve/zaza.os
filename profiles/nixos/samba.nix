{pkgs, ...}: {
  services.gvfs.enable = true;
  services.samba-wsdd.enable =
    true; # make shares visible for windows 10 clients
  networking.firewall.allowedTCPPorts = [
    5357 # wsdd
  ];
  networking.firewall.allowedUDPPorts = [
    3702 # wsdd
  ];

  environment.systemPackages = with pkgs; [cifs-utils];

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = smbnix
      netbios name = smbnix
      security = user
      #use sendfile = yes
      #max protocol = smb2
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.10. 192.168.0. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user

      allow insecure wide links = yes
    '';

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
    # sudo chown -R root /mnt/share/
    "d /mnt/share 1777 root root -"
  ];
}

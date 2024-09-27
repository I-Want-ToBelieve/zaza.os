{
  pkgs,
  lib,
  ...
}: {
  services.gvfs = {
    enable = true;
    package = lib.mkForce pkgs.gnome3.gvfs;
  };

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
    openFirewall = true;
    settings = {
      "global" = {
        "security" = "user";
        "passwd program" = "/run/wrappers/bin/passwd %u";
        "invalid users" = ["root"];
      };
      "public" = {
        "path" = "/mnt/share";
        "read only" = "yes";
        "browseable" = "yes";
        "guest ok" = "yes";
        "comment" = "Public samba share.";
      };
    };
  };

  systemd.tmpfiles.rules = [
    # after exec:
    # sudo chmod -R 1777 /mnt/share/
    "d /mnt/share 1777 root root -"
  ];
}

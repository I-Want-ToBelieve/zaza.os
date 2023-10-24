{
  config,
  pkgs,
  lib,
  ...
}: let
  github520 = pkgs.fetchurl {
    url = "https://raw.hellogithub.com/hosts";
    sha256 = "sha256-0vsH1Bbv7Yo5yOy3mt6OKh+iQWyiyZ/1k6syzmj0Pyo=";
  };
in {
  networking = {
    networkmanager = {
      enable = true;
      unmanaged = ["docker0" "rndis0"];
      wifi.macAddress = "random";
    };

    extraHosts = builtins.concatStringsSep "\n" [
      ''
        #------------ warframe hosts -------------
        # https://docs.zichou.eu.org/wfhosts

        # 解决登录问题
        121.201.75.174 content.warframe.com

        # 香港 (国内裸连 + 加速器)
        23.66.153.77 origin.warframe.com
        23.66.153.77 api.warframe.com
        23.66.153.77 arbiter.warframe.com
        # 23.194.224.167

        # 编辑日期: 2023-05-14
      ''

      # https://gitee.com/klmahuaw/GitHub520/
      (builtins.readFile "${github520}")
    ];

    firewall = {
      enable = false;
      allowPing = true;
      logReversePathDrops = true;
      allowedUDPPortRanges = [
        # warframe
        {
          from = 4990;
          to = 4995;
        }
      ];
    };
  };

  # slows down boot time
  systemd.services.NetworkManager-wait-online.enable = false;
}

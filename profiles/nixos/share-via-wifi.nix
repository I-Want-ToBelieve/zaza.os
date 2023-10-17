{ pkgs, lib, ... }: {
  services.create_ap = {
    enable = false;
    settings = {
      INTERNET_IFACE = "enp0s31f6";
      WIFI_IFACE = "wlp7s0";
      SSID = "nixoswifi";
      PASSPHRASE = "dawnsa18.";
    };
  };
}

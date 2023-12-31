{...}: {
  # @see https://raw.githubusercontent.com/lakinduakash/linux-wifi-hotspot/master/src/scripts/create_ap.conf
  services.create_ap = {
    enable = true;
    settings = {
      INTERNET_IFACE = "enp0s31f6";
      WIFI_IFACE = "wlp7s0";
      SSID = "nixoswifi";
      PASSPHRASE = "wuqimeng";
    };
  };
}

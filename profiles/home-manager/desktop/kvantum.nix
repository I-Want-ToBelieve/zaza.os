{ pkgs, ... }: {
  home.packages = with pkgs; [ libsForQt5.qtstyleplugin-kvantum ];
}

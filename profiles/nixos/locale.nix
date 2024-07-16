{
  lib,
  pkgs,
  ...
}: {
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";

    extraLocaleSettings = {LC_TIME = lib.mkDefault "en_US.UTF-8";};

    supportedLocales =
      lib.mkDefault ["en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8"];

    inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs;
      with inur;
        [
          fcitx5-gtk
          fcitx5-chinese-addons
          libsForQt5.fcitx5-qt
          fcitx5-theme-catppuccin
        ]
        ++ [
          (fcitx5-rime.override {
            rimeDataPkgs = with pkgs.nur.repos.linyinfeng.rimePackages; withRimeDeps [rime-ice];
          })
          fcitx5-mozc
        ];
    };
  };

  time = {
    timeZone = lib.mkDefault "Asia/Shanghai";
    hardwareClockInLocalTime = true;
  };
}

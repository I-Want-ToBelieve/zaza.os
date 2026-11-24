# 实体机与 QEMU 验证机共用桌面、网络和用户体验；不引入大型 base/misc suites。
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./applications.nix ./terminal-tools.nix];

  networking = {
    networkmanager.enable = true;
    useDHCP = false;
    firewall.enable = true;
  };
  time.timeZone = "America/Denver";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8"];
    inputMethod = {
      enable = true;
      type = "fcitx5";
      # 局部使用锁定版本的 ClassicUI 补丁，不覆盖其他主机的包集合。
      package = lib.mkForce (pkgs.qt6Packages.fcitx5-with-addons.override {
        fcitx5 = pkgs.callPackage ../../../pkgs/fcitx5-tahoe/engine.nix {};
        inherit (config.i18n.inputMethod.fcitx5) addons;
      });
      fcitx5 = {
        waylandFrontend = true;
        addons = [
          # 雾凇及 Lua 功能由锁定的 nixpkgs 包提供，不引入默认 Rime 方案合集。
          (pkgs.fcitx5-rime.override {
            rimeDataPkgs = [(pkgs.callPackage ../../../pkgs/fcitx5-tahoe/rime-data.nix {})];
          })
        ];
      };
    };
  };
  fonts.packages = with pkgs; [noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji];
  # Qt 6 插件放入系统搜索路径；主题选择与资源由 Home Manager 管理。
  environment.systemPackages = [pkgs.kdePackages.qtstyleplugin-kvantum];
  services.fstrim.enable = true;
  hardware.graphics.enable = true;
  users.users."i.want.to.believe".extraGroups = lib.mkForce ["wheel" "networkmanager" "audio" "video" "render"];
}

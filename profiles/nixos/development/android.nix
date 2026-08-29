{pkgs, ...}: {
  # https://nixos.wiki/wiki/Android#Building_Android_on_NixOS
  #
  # programs.adb.enable 已被移除：systemd 258 起 uaccess 规则自动处理，
  # 该选项不再有任何作用。取而代之的是直接安装 android-tools 拿到 adb 命令。
  environment.systemPackages = [pkgs.android-tools];

  programs.java.enable = true;
}

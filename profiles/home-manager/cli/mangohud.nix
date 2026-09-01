# mangohud 在 aarch64 上会拉 libstrangle，而后者是 x86-only —— 于是整台
# aarch64 机器求值失败，且报错指向 libstrangle 而不是这里。
# 它是个游戏叠加层，在非 x86 上本来也没有意义，直接整体禁用。
{
  lib,
  pkgs,
  ...
}: {
  programs.mangohud.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
}

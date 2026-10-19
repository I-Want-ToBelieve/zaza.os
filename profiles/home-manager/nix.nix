{
  pkgs,
  lib,
  ...
}:
# nix tooling
{
  home = {
    packages = with pkgs; [alejandra deadnix statix];

    sessionVariables = {DIRENV_LOG_FORMAT = "";};
  };

  # 这里刻意**不**设 trusted-users / allowed-users：home-manager 会把它们写进
  # ~/.config/nix/nix.conf，而守护进程的信任判定只读 /etc/nix/nix.conf ——
  # 否则任何用户写自己的配置就能自我提权。要改信任名单，改
  # profiles/nixos/nix.nix 的 nix.settings.trusted-users。
  #
  # substituters 则是有效的：本用户已在系统级 trusted-users 里，受信用户的
  # 用户级 substituters 会被采纳。（它与系统级那份内容相同，属冗余但不是无效。）
  nix.settings = {
    substituters = lib.mkForce [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
    ];
  };
}

{pkgs, ...}:
# nix tooling
#
# 此前这里还有一个 nix.settings 块，整块删掉了，三项逐一说明：
#
#   trusted-users / allowed-users
#     home-manager 把它们写进 ~/.config/nix/nix.conf，但守护进程的信任判定
#     只读 /etc/nix/nix.conf —— 否则任何用户写自己的配置就能把自己提权成
#     trusted-user。实测两份内容本来就是矛盾的：系统那份是
#     `root i.want.to.believe`，用户这份声称 `root @wheel @admin`，
#     生效的始终是前者。真正该改的地方是 profiles/darwin/nix.nix 的
#     nix.settings.trusted-users。
#
#   trusted-substituters（含 http://192.168.0.121:8080 即 bigboy）
#     它只是「允许使用」的白名单，而 profiles/darwin/nix.nix 把
#     substituters mkForce 成了三个镜像、**不含 bigboy**，所以这个缓存
#     从来没有被查询过。要真正启用，需要同时把它加进 substituters，
#     并把它的公钥加进 trusted-public-keys —— 那个公钥我没有，
#     所以这里只做删除，不做半吊子的启用。
#     （CLAUDE.md 记录了 NixOS 侧完全相同的一处。）
{
  home = {
    packages = with pkgs; [alejandra deadnix statix];

    sessionVariables = {DIRENV_LOG_FORMAT = "";};
  };
}

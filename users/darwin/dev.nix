{pkgs, ...}: {
  # 与 users/darwin/i.want.to.believe.nix 并列而不是共用一份参数化模板 ——
  # 两台 Mac 的用户是两个独立决定，照「跨机器的重复买隔离」那条原则办。
  programs.fish.enable = true;

  users.users.dev = {
    description = "Dev";
    shell = pkgs.fish;

    home = "/Users/dev";
  };
}

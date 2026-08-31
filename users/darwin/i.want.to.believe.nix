{pkgs, ...}: {
  # 密钥现在由 clan vars 管理，见 flake/vars.nix。注意 darwin 主机不走 clan，
  # 所以这台机上没有 vars —— 需要密钥时得单独决定方案。
  programs.fish.enable = true;

  users.users."i.want.to.believe" = {
    description = "I Want To Believe";
    shell = pkgs.fish;

    home = "/Users/i.want.to.believe";
  };
}

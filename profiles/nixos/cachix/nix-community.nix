# nix-community 的缓存凭据。
#
# 这里只声明**公钥** —— URL 在 profiles/nixos/nix.nix 的 substituters 里，
# 那是全仓库唯一的 substituters 定义处（理由见该文件注释）。
#
# trusted-substituters 的含义与 substituters 不同：它是「允许非受信用户
# 自行启用」的白名单。此前这里还列了 tuna / ustc 两个镜像，但它们本来就在
# 全局 substituters 里，列在这儿是噪音，已删。
{
  nix.settings = {
    trusted-substituters = ["https://nix-community.cachix.org"];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}

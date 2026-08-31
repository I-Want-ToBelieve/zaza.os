# 本仓库自己的最后一层 overlay —— 覆盖链的末位，见 flake/hosts.nix 的
# nixosOverlays / darwinOverlays。
#
# 目前为空。此前这里是 `skhd = prev.skhd.overrideAttrs (_: _: {})`，
# 一个不改任何东西的 override：已实测它产出的 drvPath 与裸 nixpkgs
# 逐字节相同，也就是纯粹的 no-op，容易让人误以为 skhd 被打过补丁。
#
# 文件本身保留：flake.overlays.default 是对外输出，而这也是加本地
# 包覆盖时该落笔的地方。
_final: _prev: {
}

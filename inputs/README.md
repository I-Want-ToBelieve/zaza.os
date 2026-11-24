# Krohnkite 源码输入

`krohnkite/` 是本地 Effect v4 重写仓库的公开源码快照，供 `lvlv.os` 和
`lvlv-vm` 的 Home Manager profile 选择。独立 Home Manager 模块的默认包仍由
nixpkgs 提供，其他主机不自动切换。

快照包含构建、测试、KWin QML 与配置资源，不包含 `.git`、源码子模块、
`node_modules` 或预编译 `dist`。Nix 使用固定的 pnpm lock 从源码构建；Effect
依赖版本由该 lock 固定。完整上游源码仍保留在 Krohnkite 仓库的 `.repo` 子模块
及它的发布源码 ZIP 中。`SOURCE.json` 记录原仓库基准提交和每个快照文件的 SHA-256。
UTF-8 文本统一使用 LF 换行，清单按规范化后的快照字节计算，跨平台克隆后仍可校验。

在 zaza.os 根目录更新：

```sh
python3 scripts/update-krohnkite-source.py ../Krohnkite
python3 scripts/update-krohnkite-source.py --check
git add inputs/krohnkite
nix flake update krohnkite
nix eval --impure --json --file scripts/verify/krohnkite.nix
nix build .#nixosConfigurations.lvlv-vm.config.system.build.toplevel
```

检查后再按 VM 验收流程部署。输入使用仓库内部的相对路径，克隆 zaza.os 即可
重现；不依赖开发者的 Windows 路径。Nix 2.34 的纯求值不能将相邻仓库作为越过
flake 根目录的 `path:../Krohnkite` 输入，因此这里保存快照。将来重写仓库的
flake 提交发布后，可以将输入换成已发布的 Git 提交地址。

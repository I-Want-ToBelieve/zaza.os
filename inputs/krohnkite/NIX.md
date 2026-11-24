# Nix 构建与接入

独立 flake 提供 `packages.<system>.krohnkite`、同包的 `default`、
`overlays.default`、开发环境以及包构建和真实 Qt 运行检查。
支持的求值平台为 `x86_64-linux` 与 `aarch64-linux`。

```sh
nix build .#krohnkite
nix flake check
nix develop
krohnkite-install
pnpm check
```

`krohnkite-install` 在交互式开发环境中安装锁定依赖，并用 `autoPatchelf`
适配 npm 提供的 Linux 原生执行文件和动态库。根目录的 postinstall 从已经安装的
`@effect/tsgo` 包中应用编译器补丁。Nix 格式化使用 Alejandra：`nix fmt`。

## 构建边界

`flake.lock` 固定 nixpkgs 提交
`7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f`，与 lvlv OS 当前使用的输入一致。
Node 为此输入中的 24.20.0；pnpm 由官方 npm 源码包固定为 11.22.0。
工作区锁文件继续固定 TypeScript 7.0.2、Effect 4.0.0、
`@effect/tsgo` 0.43.0 与其余工具链版本。

`fetchPnpmDeps` 使用 pnpm 11 对应的 fetcher v4，依赖内容哈希为：

```text
sha256-nJozsydt3be6TBT3bUkjc9VZRagGbBHvg4Rv/CZW4nY=
```

依赖预取是独立的固定输出 derivation。包构建在 Nix 沙箱中离线安装依赖，
跳过生命周期脚本，然后明确应用 Linux Effect-tsgo 补丁与 ELF 适配。
预取将单次下载超时设为 600 秒、并发设为 4、重试设为 4；归档前校验
Effect-tsgo 七个平台，以及 TypeScript、Rolldown、Biome、Nx、esbuild 的
Linux x64/arm64 原生包清单。pnpm 会跳过下载失败的可选包，这个检查让
缺少所需原生包的缓存直接失败，不能作为成功的依赖哈希。
构建使用 Nx 和 tsdown 重新生成全部五个包，包括 KWin 的自包含 IIFE；
构建检查执行 TypeScript native 类型检查和全部 Vitest 测试。
KWin bundle 在构建时将 native generator 降低为普通 JavaScript 状态机，
避开已复现的 Qt QV4 多窗口/垃圾回收崩溃；Babel 只用于构建，生成的 helper
内联在包中。其他模块保留原生 generator，调试 source map 由构建器组合。
源码过滤保留编译配置、包源码、测试、QML 与配置资源、许可证与上游提交记录；
`.repo`、`node_modules`、`dist`、缓存、文档、CI、Changesets 和 OS 的
`SOURCE.json` 不进入编译输入。

安装目录为：

```text
share/kwin/scripts/krohnkite/
share/krohnkite/krohnkite-1.0.0.kwinscript
share/krohnkite/krohnkite.js.map
```

脚本目录包含重新构建的代码、QML 与配置资源，以及 Krohnkite/Effect/Babel helper 许可证、
NOTICE 和固定上游提交记录。`checks.<system>.qt-runtime` 使用安装后的实际 bundle，
在 offscreen Qt 中检查窗口平铺、快捷键、配置重载和 Scope 清理。

## lvlv OS 与 lvlv VM OS

已有的 Home Manager 模块可直接选择该包：

```nix
programs.krohnkite = {
  enable = true;
  package = inputs.krohnkite.packages.${pkgs.stdenv.hostPlatform.system}.krohnkite;
};
```

仅需在目标主机 profile 中设置包，其他主机可以继续使用 nixpkgs 的默认实现。
声明式选项继续由现有模块写入 `kwinrc`；具体配置见 [CONFIGURATION.md](CONFIGURATION.md)。
本地开发接入采用 OS 仓库内 `path:./inputs/krohnkite` 的公开源码快照；
该快照包含本 flake 与锁文件，可以独立重建，不携带依赖目录或预构建 bundle。
相对路径锁仅记录路径与父级关系，不单独保存 `narHash`；快照随 OS 仓库保存，
其文件内容由 `SOURCE.json` 校验。
快照更新与来源记录由 OS 仓库的更新脚本负责。远端发布后可将 input 改为固定的
Git 提交。

修改依赖时同步更新 pnpm 锁文件与 `nix/package.nix` 中的依赖哈希，
重新执行构建和 Qt 检查。aarch64 已提供同样的固定依赖与构建定义；
当前实际验证平台为 x86_64-linux。

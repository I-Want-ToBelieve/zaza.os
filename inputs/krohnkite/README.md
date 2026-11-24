# Krohnkite · Effect v4

使用 Effect v4、TypeScript 7 和 pnpm/Nx monorepo 重写的 KWin 动态平铺脚本。
面向 Plasma 6；安装产物是自包含的 `.kwinscript`，桌面运行时不依赖 Node。

## 模块

| 包 | 职责 |
| --- | --- |
| `@krohnkite/config` | 读取、校验 KConfig，保留上游配置键与快捷键名称 |
| `@krohnkite/core` | 纯函数布局、窗口规则、表面状态和事件 reducer |
| `@krohnkite/runtime` | Effect v4 服务、Ref 状态、失败报告与 Scope 生命周期 |
| `@krohnkite/kwinscript-api` | KWin API 的 Effect 服务、类型化错误、作用域信号与回调资源 |
| `@krohnkite/kwin` | KWin 平铺适配器、窗口状态还原、QML 入口和桌面配置资源 |

`core` 支持 Tile、Monocle、Three Column、Spiral、Quarter、Stacked、Columns、
Spread、Floating、Stair、Binary Tree、Cascade 十二种布局。
构建工具放在根目录 `scripts/`；tsdown 为内部库生成 ESM，为 KWin 生成单个 IIFE。
Nx 记录模块依赖并缓存构建、类型检查和测试。
上游布局与高级选项的已验证范围、当前差异见 [COMPATIBILITY.md](COMPATIBILITY.md)。
本地验证结果见 [VALIDATION.md](VALIDATION.md)。
KWin 与 Node 的区别、Effect 的可用范围和异步限制见 [RUNTIME.md](RUNTIME.md)。
GUI、原生 `kwinrc` 文件与 Nix 声明配置的用法见 [CONFIGURATION.md](CONFIGURATION.md)。
上游 QML、配置资源和图片的迁移记录见 [RESOURCE-MIGRATION.md](RESOURCE-MIGRATION.md)。

## 源码与工具链

```sh
git clone --recurse-submodules https://github.com/I-Want-ToBelieve/krohnkite.git
cd krohnkite
pnpm install --frozen-lockfile
pnpm check
```

已有克隆使用 `git submodule update --init --recursive`。
`.repo/krohnkite` 跟踪 Codeberg 上游 `master`；`.repo/effect` 跟踪 Effect 官方 `main`
的 v4 源码。Git gitlink 和 `upstreams.json` 固定具体提交；构建使用锁定的 npm
`effect@4.0.0`，不会隐式使用不断变化的分支。更新源码时须同时更新 gitlink 与记录文件。

| 工具 | 固定版本 |
| --- | --- |
| pnpm | 11.22.0 |
| TypeScript native | 7.0.2 |
| Effect | 4.0.0 |
| Vitest / `@effect/vitest` | 5.0.3 / 4.0.0 |
| `@effect/tsgo` | 0.43.0 |
| Nx | 23.2.1 |
| tsdown | 0.23.0 |
| Ultracite / Biome | 7.9.4 / 2.5.15 |
| Changesets CLI | 3.0.3 |
| tsx / taze | 4.23.15 / 21.3.0 |

根 manifest 保留 `"@typescript/native": "catalog:typescript"` 和
`"typescript": "catalog:typescript"`。`@typescript/native` 是命名 catalog 中
指向 `npm:typescript@7.0.2` 的 alias，因为 TypeScript 7 正式 native 编译器发布在
`typescript` 包名下。安装后 `effect-tsgo patch` 接入 Effect 的 native 类型诊断。

```sh
pnpm format          # Ultracite，使用 Biome preset
pnpm typecheck       # TypeScript 7 native + Effect 诊断
pnpm test            # Vitest + @effect/vitest，各模块行为测试
pnpm test:all        # 单个 Vitest 会话运行全部项目
pnpm test:watch      # 监听模式
pnpm build           # tsdown，经 Nx 调度
pnpm release:assets  # 生成并验证 release 资产
pnpm graph           # Nx 依赖图
pnpm deps:check      # taze 检查可升级依赖
```

## Qt 运行边界

KWin 的 QML 引擎与 Node 的 JavaScript 环境有差异。应用构建提供局部的
`globalThis` 和局部 Object 兼容处理，补齐 `fromEntries`、`hasOwn`，并修复 Qt
复制 Symbol 属性的问题。Qt 的内置方法不可写，兼容层使用脚本局部的 Object
facade。构建还延迟 Effect 中
仅供纳秒计时等功能使用的 BigInt 初始化。不会用浮点数替代 BigInt 运算。
KWin 回调通过同步 Effect 边界处理，计时与配置重载使用 QML Timer；脚本不使用
Effect 的异步平台、纳秒时钟、网络或 Node 平台服务。

`tests/qml/runtime.qml` 在真实 Qt 引擎中验证 Effect 启动、双窗口平铺、Monocle
快捷键、配置重载与信号断开。Linux CI 在完整构建后执行该测试；打包验证还会在
屏蔽 Node、浏览器和 Qt 缺失能力的 JavaScript sandbox 中载入 IIFE。
`tests/qml/kwin.qml` 是实际 KWin 集成测试入口，使用临时命名空间，仅管理两扇
标题为 `Krohnkite rewrite check 1/2` 的测试窗口。
安装 `kwin_wayland`、`kitty`、`dbus-run-session` 后，可运行
`bash scripts/kwin-smoke.sh`；测试在独立虚拟显示和 D-Bus 会话中进行，日志保存在
`dist/kwin-smoke.log`。

## 版本与发布

```sh
pnpm changeset
pnpm version:packages
pnpm check
pnpm release:tag
git push origin main
# 将 VERSION 替换为 packages/kwin/package.json 中的版本号。
git push origin '@krohnkite/kwin@VERSION'
```

Changesets 将五个私有工作区包作为固定版本组管理，并为私有应用创建版本标签。
推送前先提交版本与 lockfile 变更，或合并自动生成的版本 PR。发布时只推送 KWin
的一个标签；[GitHub 不会为同时推送超过三个标签产生标签事件](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#push)。
`Version packages` workflow 在 `main` 上创建版本 PR。
`Release KWin assets` 在 `vVERSION` 或 `@krohnkite/kwin@VERSION` 标签上运行，也可
手动选择已有标签。版本与 KWin package manifest 不一致时构建失败。
GitHub 发布只需要仓库的 `GITHUB_TOKEN`，无需 npm 发布凭据。

`dist/` 产出：

- `krohnkite-VERSION.kwinscript`：KWin 安装包，包含 QML、配置界面、bundle 和许可证。
- `krohnkite-VERSION.source.zip`：包含两份固定上游源码和 lockfile 的源码归档。
- `krohnkite-VERSION.js` 与 `.js.map`：bundle 和 source map。
- `krohnkite-VERSION.provenance.json`：工具链、版本与上游提交记录。
- `SHA256SUMS`：以上资产的 SHA-256 校验。

源码 ZIP 附带两份上游的完整文件哈希清单，可在没有 `.git` 的环境重新打包。
打包验证会确认源码未改动，并检查重新生成的 `.kwinscript` 与原产物哈希一致。

Windows 与 Ubuntu CI 都运行 lint、native 类型检查、测试、构建和打包验证。
源码仓库推送后，GitHub 才会执行这些 workflow。

## 安装

```sh
kpackagetool6 --type KWin/Script --install dist/krohnkite-1.0.0.kwinscript
# 已安装 krohnkite 时使用 --upgrade 替代 --install。
```

在 KDE 系统设置的「窗口管理 → KWin 脚本」启用 Krohnkite。
插件 ID 仍为 `krohnkite`，已有 KConfig 与快捷键绑定可继续使用。
lvlv.os 与 lvlv-vm 可共用同一发布资产，通过各自的模块开关启用。

仓库也提供 Nix flake，从锁定的 pnpm 依赖构建源码包：

```sh
nix build .#krohnkite
nix flake check -L
nix develop
```

构建接口与 lvlv OS 接入说明见 [NIX.md](NIX.md)。

Nix 包将自包含 JavaScript、QML 和 GUI 配置资源安装到
`share/kwin/scripts/krohnkite`。构建与测试使用 Node，安装后的脚本由 KWin 执行。

## 默认快捷键

25 个默认绑定均为 Meta 加一个按键，另外 14 个 action 默认不绑定。
已保存的自定义绑定会继续生效，可在系统设置的 KWin 快捷键页面修改。
独立安装时，请在该页面清除占用相同组合的 KDE 内置绑定。

| 动作 | 默认按键 |
| --- | --- |
| 焦点左 / 下 / 上 / 右 | Meta+Left / Meta+Down / Meta+Up / Meta+Right |
| 焦点下一项 / 上一项 | Meta+End / Meta+Home |
| 移动左 / 下 / 上 / 右 | Meta+F1 / Meta+F2 / Meta+F3 / Meta+F4 |
| 缩小 / 增大宽度 | Meta+[ / Meta+] |
| 缩小 / 增大高度 | Meta+F11 / Meta+F12 |
| Increase / Decrease | Meta+I / Meta+U |
| 切换浮动 / 全部浮动 | Meta+F / Meta+O |
| 下一 / 上一布局 | Meta+N / Meta+P |
| 旋转 / 局部旋转 | Meta+R / Meta+Y |
| 设为主窗口 | Meta+S |
| Tile / Monocle 布局 | Meta+T / Meta+M |

## 许可证

MIT。保留 Eon S. Jeon、Vjatcheslav V. Kolchkov 的原始版权声明，
Effect 许可证随发布包分发。参见 `LICENSE`、`NOTICE` 与 `.repo/` 的上游许可证。

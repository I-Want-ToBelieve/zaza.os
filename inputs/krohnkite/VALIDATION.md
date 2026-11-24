# 验证记录

2026-10-04，最新正式转换版本在 Windows 目标仓库执行 `pnpm check`，全部通过。测试使用 Vitest 5.0.3
与 `@effect/vitest` 4.0.0，最终 Linux Nix 构建实际执行 **329 项**测试。
Effect 程序使用 `it.effect`，纯函数与同步入口使用普通 `it`。
最新 4ce08863... bundle 的正式 Nix 构建、安装后原生 Qt 检查及新 Plasma 会话
live 验收全部通过。下表区分当前结果、历史同步策略修复包和
生成器转换实验；历史或实验结果不代替当前包验证。

| 检查 | 结果 |
| --- | --- |
| Ultracite 7.9.4 / Biome 2.5.15 | 全仓库检查通过 |
| TypeScript 7.0.2 native / `@effect/tsgo` 0.43.0 | 根工具与五个工作区包通过 |
| 配置与核心行为 | 通过，包含 216 个上游布局基准、原生数值、多行规则及跨 QML realm 的数组解码 |
| Effect runtime、独立 KWin API、适配器与 Qt 构建工具 | 通过，包含部分最大化/最小化状态还原、内部窗口过滤、资源清理、配置读取失败后保留与恢复、浮动/忽略规则重载、关闭提示、同步调度预算、hiddenChanged 及生成器 / 源图组合回归 |
| Nx / tsdown | 五个模块全部构建成功 |
| 本地发布资产 | KWin 包、JS、source map、源码 ZIP、provenance、SHA256SUMS 生成与校验通过；远端 release 未运行 |
| 受限 JS 环境 | 屏蔽 Node/浏览器/Qt 缺失 API，模拟不可写内置对象和 Symbol 复制差异；完整运行时生命周期通过 |
| 安装包依赖 | source map 包含独立 API 包；不包含 Vitest 或任何测试源文件 |
| 源码 ZIP | 无 `.git` 重新打包得到相同 KWin 包；上游源码篡改及额外文件被拒绝 |
| 历史同步策略修复包的 Nix 检查 | hfga 包离线安装、Linux 类型检查、构建及 318 项测试通过；JS 与 a7fd8c08... 相同 |
| 历史同步策略修复包的真正 Qt 压力检查 | 未通过；39 原生快捷键信号 / 12 原生窗口在 Qt 6.11.2 启动期间 SIGSEGV |
| 历史同步策略修复包的真正 KWin 文件配置检查 | hfga 实际安装目录通过 8 → 16 间距、非法值/缺键回退及恢复；不计为当前包或生产会话通过 |
| 生成器转换实验的真正 Qt 压力检查 | 通过；默认 Qt 环境保留完整 39 快捷键 / 12 原生窗口和全部清理断言，不计为发布包验证 |
| 最终源码依赖预取 | 通过；420/420 包与 17 个原生平台 manifest 完整性检查通过 |
| 最终正式包的 Nix 构建 | 通过；k32brf86... 包离线类型检查、五包构建及 329 项测试通过，Linux / Windows bundle 相同 |
| 最终正式包安装后的真正 Qt 检查 | 通过；Qt 6.11.2 部分最大化、内部窗口、39 快捷键 / 12 原生窗口压力及 Scope 清理检查全部通过 |
| 最终正式包的 KWin live 检查 | 通过；新会话四阶段几何、真正 D-Bus 快捷键与文件重载验证通过，实际 compositor PID 不变，清理错误为空 |
| 历史真正 Qt QV4 | Qt 6.11.2 中启动、两窗口 Tile/Monocle、配置重载及信号清理通过 |
| 历史真正 KWin | KWin 6.7.5 的独立虚拟显示与 D-Bus 会话中，生产 main.qml 与全部 Loader、两窗口原生文件配置重载、卸载后窗口关闭均通过 |
| 历史 Nix 源码包 | 锁定 pnpm 11.22.0，离线安装下载 0 包；Linux TS7/Effect-tsgo、五包构建、类型检查与当时的 312 项测试通过 |
| 历史 Nix 安装内容 | 安装后的 bundle 通过真实 Qt 检查；实际 Nix 脚本目录通过真实 KWin 原生文件配置测试 |
| 历史 Nix flake 输出 | x86_64-linux 输出检查及 devShell 版本检查通过；aarch64-linux 已求值，尚未实际构建 |

历史同步策略修复包的 Windows / Nix bundle 大小为 328,018 字节，SHA-256：
`a7fd8c08be5f0f289c1b25d2d663ad1dd0ad2373a3655c8fff3b81f0e18b885b`。
新增回归验证同步入口在低操作预算下不调用 `shouldYield` 或调度任务，覆盖启动、
事件、配置、snapshot 和 Scope 清理；真正异步 Effect 仍被拒绝，启动失败时释放
已经取得的资源。`hiddenChanged` 独立通知现在触发可见性刷新、恢复两窗口平铺，
并在卸载后断开订阅。以上回归已包含在当时的 318 项 Vitest 检查中。

Qt 压力 fixture 已加入 `tests/qml/runtime.qml`：39 个原生快捷键信号、12 个
原生窗口、动态窗口事件、GC、布局切换、配置重载及卸载清理，覆盖超过默认
2048 操作预算的同步路径。历史同步策略修复包的 Nix 离线构建通过，真实 Qt
压力检查发生 SIGSEGV，GDB 栈位于 QV4 自动 GC
标记阶段。扩大 JS/GC 栈及调用深度、降低 inline 步数、解释器执行均未解决。
把窗口与信号全部替换为普通 JS 对象，或仅注册大量快捷键而没有窗口，也会崩溃。
这些诊断没有削弱正式 fixture 的原生对象、GC 与清理覆盖。

生成器转换实验资产为 **371975 字节**，SHA-256：
`384f9516cc97552c902690a4bbc41933959012e72a19d6405046bc8a5c1f41f3`。
14 个原生生成器 / 65 个 yield 转换为普通 JavaScript 状态机后，同一完整 Qt
fixture 在默认环境中退出 0，输出 `KROHNKITE_QT_SYNC_BUDGET_OK` 和
`KROHNKITE_QT_SMOKE_OK`，包含动态添加第 12 窗、GC 后 Monocle/Tile 切换、
几何信号、配置重载、Scope 清理及 dispose 后 GC / 迟到信号门禁。
证据在任务 workspace 的 `artifacts/krohnkite-regenerator-qt-result.txt` 与
`artifacts/krohnkite-qt-stress-investigation.json`。
首个正式构建的生成器转换 bundle 为 **349456 字节**，SHA-256：
`326db75651ee06e30c052babedf92b8f2d0de9af1baf7cbef691da8d91e321ad`。
它在去除临时诊断日志的同一稳定压力 fixture 中通过，全部原生窗口、信号、
GC 与清理断言保留，证据为任务 workspace 的
`artifacts/krohnkite-production-lowered-qt-result.txt`。
这是随后数组解码修复前的中间构建；它不计为最新 Nix 包或生产会话通过，
也未确证某个 Qt bug 为唯一根因。

补充 QML realm 数组配置解码回归后的历史中间 bundle 为 **350087 字节**，
SHA-256：`691f121f97b5730176c89fdbec0f696e1d4de75a6642b0ce9a6949ccf4b19870`。
该版本在 Windows 目标仓库执行 `pnpm check`，**327 项**测试及本地发布资产
生成、校验通过；同一完整原生 Qt 压力 fixture 再次退出 0，输出
`KROHNKITE_QT_SYNC_BUDGET_OK` 与 `KROHNKITE_QT_SMOKE_OK`。
证据为任务 workspace 的 `artifacts/krohnkite-final-lowered-qt-result.txt`。
该 327 项版本随后在真实会话中暴露了部分最大化轴还原及自身通知被当成第三窗的
问题；最终版本已修复，并增加原生回归。旧 691f121f... 结果不代替最终验收。

最终正式 bundle 为 **350477 字节**，SHA-256：
`4ce08863b5a109973b3753c80f3547e594b70eff78d941404b0fdd03794850b2`。
Windows `pnpm check` 与本地发布资产校验通过；Linux Nix 构建实际执行 **329 项**
测试，输出与 Windows bundle 逐字节相同。最终 Nix 包为：

```text
/nix/store/k32brf86acwjni7228h528cj5d88rsvi-krohnkite-effect-1.0.0
```

包 derivation 的 store 哈希为 `vvwa3aaw2alpmvs1myfpfdww1na6fdg2`；安装后 Qt 检查
输出的 store 哈希为 `pbq998akb7bqj42xh1vqnmfrh4d3b6g6`。真正 Qt 6.11.2 检查
输出 `KROHNKITE_QT_PARTIAL_MAXIMIZE_OK`、`KROHNKITE_QT_INTERNAL_WINDOWS_OK`、
`KROHNKITE_QT_SYNC_BUDGET_OK` 与 `KROHNKITE_QT_SMOKE_OK`。

最终干净 Plasma 登录开始于 `2026-10-04T04:54:39-06:00`，live 验收记录为
`/root/krohnkite-effect-live-results-1791111330-25969/result.json`，本地日志在任务
workspace 的 `artifacts/krohnkite-final-live-canary.log`。两个 kitty 窗口所在
PlacementArea 为 `(0,32,1536,832)`，四阶段实际几何如下：

| 阶段 | 窗口 1 `(x,y,width,height)` | 窗口 2 `(x,y,width,height)` | 两窗 maximizeMode |
| --- | --- | --- | --- |
| 默认 Tile，间距 8 | `(8,40,756,816.4)` | `(772,40,756,816.4)` | 0 |
| 真正快捷键切换 Monocle | `(8,40,1520,816.4)` | `(8,40,1520,816.4)` | 3 |
| 真正快捷键返回 Tile | `(8,40,756,816.4)` | `(772,40,756,816.4)` | 0 |
| 文件配置重载，间距 16 | `(16,48,744,800.4)` | `(776,48,744,800.4)` | 0 |

验收没有强制初始 Tile；KGlobalAccel D-Bus 调用 Monocle 1 次、Tile 2 次，
并核对真正的几何变化。KWin service wrapper PID **25422**、实际 compositor PID
**25426** 在验收前后相同，`NRestarts=0`，`cleanupErrors=[]`；基线、最终及新增的
失败系统单元列表均为空。系统已完成 dry-activate、test、profile、boot 和单一
干净 Plasma 登录；这不表示最终新系统已经冷启动，实体机仍只求值、没有部署。
`artifacts/krohnkite-final-live-kwin.log` 同时记录了真实
`KROHNKITE_INTERNAL_WINDOW_TYPES [KWin::InternalWindow(0x...)]`；这些通知被排除，
返回 Tile 后两扇 kitty 都恢复 816.4 的完整高度。

历史同步策略修复版本的 Nix 包为
`/nix/store/hfga4rb85019j2n1cx582fjyvsipg34n-krohnkite-effect-1.0.0`。
其真实 KWin 文件配置结果在任务 workspace 的
`artifacts/krohnkite-followup-kwin.log`；两窗布局和原生 `readConfig` / `reconfigure`
实际通过，但不替代完整压力检查或常规生产会话验收。

历史验证在 1280×800 的独立 KWin 输出中，Tile 几何为 `(8,8,628,784)` 和
`(644,8,628,784)`；Monocle 两扇窗口均为 `(8,8,1264,784)`。

上述历史真实 Qt/KWin 测试使用目标仓库生成的修复前 bundle，大小 328,791 字节，SHA-256：
`93e58968818211ef06e2277ad282bfcb6e4bd0c42f8c946aa87929788e2f68ce`。
当时 Nix 从源码构建的 JavaScript 与它逐字节相同；这些几何结果未用于验证新 hash。
`@krohnkite/kwinscript-api` 仅依赖 Effect；KWin 适配器实际使用其 Layer、
类型化边界、信号订阅和一次性回调资源。通用 runtime、core、config 不依赖它。

历史原生文件配置测试使用真正的 `KWin.readConfig` 和生产 QML，按顺序修改
`kwinrc` 并调用 `org.kde.KWin.reconfigure`，没有模拟读取器或主动调用运行时重载。
间距 16 时几何为 `(16,16,616,768)` 和 `(648,16,616,768)`；左间距为非法值或
删掉该键时回退零，几何为 `(0,16,624,768)` 和 `(640,16,624,768)`；恢复 8 后
回到原始几何。独立 KWin 在脚本卸载、窗口关闭后仍存活，临时目录清理通过。
可复跑 `bash scripts/kwin-config-smoke.sh`，或用 `--package` 指定 Nix 安装目录。

历史 Nix 产出的 `.kwinscript` 有 14 个排序的文件条目，均使用 1980-01-01 UTC 时间，
没有额外 ZIP 字段；源码构建不读取预编译 `dist` 或 `.repo`。
嵌套的 `path:./inputs/krohnkite` 输入也已实际构建和执行 Qt 检查，源码提取先
规范化 Nix 路径，避免 `/./` 导致过滤器漏掉依赖清单。

上游子模块索引均为 Git mode `160000`：

- Krohnkite：`ade1de7488cd84185f6f14efd4fba8e8b0db7ddb`。
- Effect v4：`f84f41e866fa2f5740edb74275facf25d9abf9e4`。

GitHub workflow 已配置并固定 Actions 提交。尚未推送仓库，因此这里没有宣称远端
GitHub CI 或 release 已运行。高级配置兼容范围参见 `COMPATIBILITY.md`。

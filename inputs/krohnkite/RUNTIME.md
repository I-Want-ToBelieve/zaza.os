# KWin 与 Effect 的运行边界

安装后的 Krohnkite 在 KWin 的 Qt JavaScript 引擎中执行。Node 负责开发、
Vitest、Nx、tsdown 和发布打包；桌面上的 `.kwinscript` 不启动 Node。
本项目使用 `declarativescript`，由 QML 入口注入 workspace、配置、快捷键、
Timer 和 D-Bus 回调。KDE 同时支持普通 JavaScript 脚本，两种入口的全局对象
和导入方式不能混用。参见 [KDE 脚本教程](https://develop.kde.org/docs/plasma/kwin/)。

配置由 `KWin.readConfig` 读取 `kwinrc` 的 `[Script-krohnkite]`。手动修改文件后，
调用 KWin 的 D-Bus `reconfigure`；QML 收到 `Options.configChanged` 后进行 100ms
防抖，再同步读取并应用变更。读取的是 KWin 缓存中的 KConfig，重复轮询不能
替代 KWin 重读文件。路径、命令、INI 示例与容错规则见 [文件配置](CONFIGURATION.md)。

| 边界 | Node | 本项目的 KWin/QML |
| --- | --- | --- |
| JavaScript 引擎 | V8，开发机提供现代 ECMAScript 和 Node API | Qt QV4；语言能力随 Qt 版本变化 |
| 模块加载 | npm 包、ESM、CommonJS，由 Node 解析 | 构建时将工作区与 Effect 打成单个 IIFE，由 QML 导入 |
| 外部能力 | `node:fs`、进程、网络、Node 定时器等 | KWin 的 workspace、Qt 属性和信号；附加能力由 QML 显式注入 |
| 定时与回调 | Node 事件循环及 `setTimeout` 等 | Qt 事件循环、QML Timer、Qt 信号及 D-Bus 回调 |
| 窗口对象 | 测试中的 JavaScript 替身 | C++ 所有的 QObject 包装；窗口销毁后访问可能失败 |
| 卸载 | 进程或测试运行时结束 | QML context 销毁；必须及时释放回调、断开信号 |

Qt 官方文档列出 ECMAScript 2016 基线与部分新增语法，并说明 QML 全局对象
受到写入限制。不能因为 TypeScript 接受代码，就认定 Qt 运行时具备相应能力。
本项目实测 Qt 6.11.2 时还发现 `globalThis`、BigInt、部分新 Array/Object 方法
和 Symbol 属性复制行为的差异。此处的测试结果限定于已经验证的环境；Qt 官方
文档的版本会继续变化。参见 [Qt JavaScript 宿主](https://doc.qt.io/qt-6/qtqml-javascript-hostenvironment.html)
和 [Node 全局 API](https://nodejs.org/api/globals.html)。

## 对 Effect v4 的影响

`Effect.gen`、typed error、Context.Service、Layer、Ref 和 Scope 可用于我们的
同步事件路径。Effect 不要求每个应用运行在 Node，但它的默认异步平台有宿主
假设。锁定版本的 `Clock.sleep` 使用 `setTimeout/clearTimeout`，Scheduler 使用
Promise 微任务或定时器，部分异步接口使用 AbortController，纳秒时钟与部分
tracing 路径使用 BigInt。源码见 `.repo/effect/packages/effect/src/internal/effect.ts`
及 `Scheduler.ts`；它们必须随 Effect 升级重新审查。

当前设计在 Qt 回调入口调用同步 Effect 运行边界，以 FIFO 串行处理事件，并在
应用几何命令时抑制自身触发的几何回调。同步 runner 通过
`Effect.runSyncExitWith` / `Effect.runSyncWith` 提供 v4 的
`Scheduler.PreventSchedulerYield = true` Reference，覆盖启动、事件处理、
配置变更、snapshot 和 Scope 清理，跳过运行循环的自动让出检查。这是本项目
明确的同步执行策略。锁定版本的默认操作预算是 2048，判断依据是操作计数，
不依赖 elapsed time；默认 `runSyncExit` 也会同步排空已调度的让出任务。
参见固定 commit 的 [Scheduler 定义](https://github.com/Effect-TS/effect/blob/f84f41e866fa2f5740edb74275facf25d9abf9e4/packages/effect/src/Scheduler.ts#L264-L308)
与 [同步 runner](https://github.com/Effect-TS/effect/blob/f84f41e866fa2f5740edb74275facf25d9abf9e4/packages/effect/src/internal/effect.ts#L5780-L5804)。

真实 KWin 会话曾在启动 compositor observers 时出现 `AsyncFiberError`；不能
据此认定默认自动让出就是根因。最终版本已通过 Nix 安装包检查与真实 KWin
会话中的窗口、快捷键和配置重载验收，验证范围见 [VALIDATION.md](VALIDATION.md)。
禁用自动让出不会把真正的异步 Effect 变成同步：同步 runner 仍拒绝需要等待的
`Effect.sleep`、Promise I/O 等操作。计时和虚拟键盘 D-Bus 查询的等待由 Qt
Timer / D-Bus 回调桥管理，并绑定 Scope 的取消与清理；每次回调内的 Effect
处理保持同步。将来引入异步 fiber 时，需要同时实现并实测 Qt Scheduler、
Clock、中断与取消适配；仅包装一个 QML Timer 不等于提供完整的 Effect 异步平台。

构建插件为应用提供局部 Object/globalThis 兼容层，并延迟未使用路径中的 BigInt
初始化。它没有实现 BigInt；纳秒计时等功能仍不在当前支持范围内。也没有导入
`@effect/platform-node`，也不向受限的 QML 全局对象安装 Node API 或 Promise /
timer polyfill：这些补丁无法提供 Qt 对象的作用域、取消与完整的 Effect 异步平台。
Effect fiber 是协作式执行，不能替代工作线程；耗时的
同步布局或回调仍会占用 KWin 的事件处理时间。

源图测试覆盖业务源码、独立 API 包和 Babel 两阶段转换的组合映射。
既有 `deferEffectBigInt` 模块转换返回 `map: null`，因此经该步骤改写的
Effect `Duration` / 内部 Effect 模块，不保证每个位置都能精确映射到原始
源码行列。source map 可用于已经覆盖的诊断路径，不能描述为全库逐行完美映射。

Qt 6.11.2 的历史压力检查暴露了原生生成器执行路径的限制。当时同步策略修复包的
318 项 Node 测试、Nix 离线构建和独立 KWin 文件配置检查均通过，但同一
328018 字节 bundle 在 39 个快捷键、12 个原生窗口的 QV4 用例中启动时
SIGSEGV，GDB 栈落在自动 GC 的 `MarkStack::drain`。纯 JavaScript 信号替身和
零窗口的大量订阅也能复现，因此不能仅归因于 QObject 或几何回调。
扩大 JS/GC 栈、调用深度、降低 inline 步数以及使用解释器均未解决。

构建插件现在将 Qt 资产中的生成器转换为普通 JavaScript 状态机；转换实验与
正式构建的 bundle 均在默认 Qt 环境中通过相同的 39 快捷键 / 12 原生窗口用例，
包括显式 GC 后信号处理、布局切换、配置重载、Scope 清理和卸载后信号门禁。
最新正式 bundle 为 350477 字节，SHA-256 为
`4ce08863b5a109973b3753c80f3547e594b70eff78d941404b0fdd03794850b2`；
Windows 目标仓库的 `pnpm check`、本地发布资产校验和 Linux Nix 离线构建的
329 项测试均通过，两个环境产出的 bundle 逐字节相同。
Nix 安装后的包通过默认 Qt 6.11.2 环境中的完整原生压力检查，以及部分最大化
还原和内部窗口过滤回归；新 Plasma 会话中的平铺、真正 D-Bus 快捷键调用及
`kwinrc` 重载也通过，实际 compositor PID 在验收前后保持不变。
源代码仍使用 Effect v4，
转换只发生在 Qt 资产构建阶段。该结果证明转换可避开已观测到的触发路径，
这些结果分别来自源码构建、安装后检查与真实会话；没有用实验资产代替正式包。
Qt 的 [QTBUG-149512 生成器修复](https://github.com/qt/qtdeclarative/commit/8a8473f70dde11b9ab63a1dda2c9cd0b48cae26b)
是相关候选，但当前没有证明这次崩溃就是该问题。

## 包的职责与测试

`@krohnkite/kwinscript-api` 负责宿主类型、Effect 服务和作用域资源。它将 Qt
调用异常转换为携带操作与目标的 `KWinApiError`，管理信号订阅与一次性回调，
并通过 Layer 提供注入的宿主能力。当前覆盖 Krohnkite 使用的 API，扩展时仍应
逐项核对 [KWin API](https://develop.kde.org/docs/plasma/kwin/api/)。
作用域关闭时先停用回调，再尝试断开信号或取消请求；即使宿主清理失败，迟到的
回调也不能继续操作窗口。一次性回调还需要处理注册期间同步完成或卸载的情况，
避免重复交付和漏掉取消函数。

`@krohnkite/kwin` 负责把宿主事件翻译成平铺引擎事件、执行布局命令、管理窗口
状态还原和 QML 入口。`runtime` 面向通用 Compositor 服务，`core` 保持纯函数。
平台错误在适配器映射成 `CompositorError`，避免让核心依赖 Qt 类型。

KWin 6.7 的内部 QML 通知和拖动预览窗口也会出现在窗口列表中，且类型为
Normal；`isInternal()` 没有暴露为脚本属性。适配器利用固定 Qt 版本的 QObject
字符串中精确的 `KWin::InternalWindow(` 类名前缀，在订阅和读取元数据之前
排除这些窗口，避免把自身通知当成第三扇平铺窗口。内部窗口关闭后，其
`minSize` / `maxSize` 读取器可能仍会直接访问已经清空的 QWindow 指针；
JS 异常处理不能保护这种原生访问。参见 [KWin 内部窗口实现](https://github.com/KDE/kwin/blob/v6.7.5/src/internalwindow.cpp)
和 [Qt QObject 字符串实现](https://github.com/qt/qtdeclarative/blob/v6.11.2/src/qml/jsruntime/qv4qobjectwrapper.cpp)。
最终 live 日志也记录了真实 `KWin::InternalWindow(0x...)` 类型，返回 Tile 后
两扇 kitty 保持完整高度。
部分最大化状态还原按 KWin 的垂直位 1、水平位 2，分别传给
`setMaximize(vertical, horizontal)`；原生 Qt 检查覆盖两个单轴状态。

测试使用 Vitest 5 和 `@effect/vitest` 4。Effect 程序用 `it.effect`，测试运行时
提供 Scope 与测试服务；纯函数和同步 Qt 入口用普通 `it`。作用域资源、失败恢复
和回调取消是行为测试重点。Node 中的测试通过后，还需要运行受限 JavaScript
sandbox、真正 Qt QV4 和独立 KWin 会话测试，因为 Vitest 本身不模拟 Qt 的宿主
限制或 QObject 生命周期。

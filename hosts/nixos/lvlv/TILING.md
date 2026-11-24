# Krohnkite 平铺

`lvlv.os` 与 `lvlv-vm` 的普通用户共用 Krohnkite 配置。
本轮将 lvlv profile 的包选择切换为独立 `inputs.krohnkite` 提供的源码构建包：
`inputs.krohnkite.packages.${pkgs.stdenv.hostPlatform.system}.krohnkite`。
它在 TypeScript monorepo 中使用 Effect v4 重写上游逻辑，再构建 KWin 可加载的
JavaScript 与 `.kwinscript` 资源，当前包版本为 **1.0.0**。
输入为仓库内的 `path:./inputs/krohnkite`：源码快照由 zaza.os 的 Git 提交保存，
`SOURCE.json` 记录基准提交与逐文件 SHA-256；`flake.lock` 记录相对输入路径和
依赖关系，不以 `narHash` 固定该目录内容。更新步骤见
[inputs/README.md](../../../inputs/README.md)。
上游源码来自 [anametologin/Krohnkite](https://codeberg.org/anametologin/Krohnkite)，
原件以 submodule 保留在独立 Krohnkite 仓库的 `.repo/krohnkite`。
模块的默认包仍为 nixpkgs 稳定包，只有选择 lvlv profile 的两台主机切换到重写版。
最终版本在构建时转换 Qt 资产中的生成器，Windows `pnpm check`、本地发布资产
校验和 Linux Nix 构建的 **329 项**测试均通过。350477 字节的 4ce08863... bundle
在两个环境逐字节相同；安装包通过 39 快捷键、12 原生窗口 Qt 6.11.2 压力检查，
以及部分最大化还原和内部窗口过滤回归。前一轮 sacpcjp2... VM 系统已激活，并在
单一干净 Plasma 会话中通过 Tile / Monocle、真正快捷键和 8 → 16 间距文件重载
canary；实际 compositor PID 保持不变。最新 Meta 单键版本来自源码提交
`120ef471b4c37fa540e15693843df033254b64b9`，VM 已激活 `6jd0q95m...` 系统，
全部 39 个 action 的注册键码与声明逐项一致，25 个启用绑定只有 Meta 修饰键，
14 个未启用绑定为空，并通过真实 QMP 键盘事件 `Meta+M` / `Meta+T` 的几何验收。
这是新会话验收，尚未冷启动最新系统；
实体机仍只求值，没有部署。历史生成器崩溃与诊断探针问题保留在验证记录中，见
[VALIDATION.md](VALIDATION.md)。无需运行上游安装脚本。

## 模块入口

- [modules/home-manager/krohnkite.nix](../../../modules/home-manager/krohnkite.nix)
  定义 `programs.krohnkite.{enable,package,settings,shortcuts}`，默认关闭。
  安装脚本资源，并通过 plasma-manager 管理 KWin 配置与快捷键。
- [profiles/home-manager/desktop/krohnkite.nix](../../../profiles/home-manager/desktop/krohnkite.nix)
  选择 lvlv 的默认行为；与 MacTahoe 外观、面板和输入法模块独立。
- [flake/hosts.nix](../../../flake/hosts.nix) 的 `lvlvUsers` 为两台主机注册并启用此配置。
  未选择此 profile 的主机保持默认关闭。

默认自动平铺普通窗口，屏幕四边和窗口之间保留 8 像素间距。
保留 MacTahoe 窗口装饰和标题栏；对话框及工具窗口浮动，忽略 Plasma、Vicinae、
Flameshot 和输入法窗口。KDE 门户屏幕选择器及 CopyQ 也显式排除，
避免没有标记为对话框的工具窗口被自动平铺。
布局按上游规则分别应用到屏幕、活动和虚拟桌面。

在 Home Manager 用户配置中可以独立覆盖：

```nix
programs.krohnkite = {
  enable = false; # 覆盖 profile 的 mkDefault，关闭平铺
};
```

或者自定义已启用模块：

```nix
programs.krohnkite.settings.screenGapBetween = lib.mkForce 12;
programs.krohnkite.shortcuts.KrohnkiteToggleFloat = lib.mkForce "Meta+F";
```

`settings` 使用上游 `res/config.xml` 的原始键名；`shortcuts` 使用 `res/shortcuts.qml`
的 action 名称。属性会合并，覆盖 profile 中已有值时使用 `lib.mkForce`。
`package` 允许换用其他兼容的 Nix 包。

## 文件配置

运行时使用当前用户的 `${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc`，
原生 KConfig 分组为 `[Script-krohnkite]`；脚本启用值仍为
`[Plugins]` 下的 `krohnkiteEnabled=true`。
声明式 `programs.krohnkite.settings` 通过 plasma-manager 写入同一分组。
需要保留的设置应写入 Home Manager 配置；手动修改其管理的键可能在下次激活时
被声明式值覆盖。独立 Krohnkite 源码仓库的 `CONFIGURATION.md` 和
`packages/config/examples/kwinrc` 提供完整文件示例。

已经运行重写版时，可以在现有文件中合并设置，再由当前 Plasma 用户执行：

```sh
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapBetween 8
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
```

`reconfigure` 让 KWin 重读文件，脚本在配置变更信号后防抖刷新。
单独编辑文件或重复调用 `readConfig` 不会主动重读磁盘。
间距及浮动、忽略分类规则可在现有窗口上更新；手动浮动覆盖继续保留。
现有布局状态继续使用原来的选择，改变按桌面或活动分组可能建立新的布局状态。
浮动窗口的初始尺寸规则用于新窗口，已有的浮动几何不会因配置重载自动重算。
设置重载与替换脚本包是两个不同操作：更换包或 JavaScript 后，退出并重新登录
Plasma，确保新的会话只加载新包的一份脚本实例。

## 上游资源

重写版保留上游 `shortcuts.qml`、`popup.qml`、`dbus.qml` 与 `dragpreview.qml`，
分别用于快捷键、布局通知、DBus 桥接和拖动预览。`main.qml` 已迁移为 Effect
运行时入口；`config.xml` 与 `config.ui` 保留原生配置项目和设置界面。
这些资源与生成的 JavaScript 一起安装到 KWin script 包。
上游 `img/screenshot.png` 与 `img/conf.png` 保存在独立源码仓库的 `docs/images/`，
作为历史界面和配置入口示例，不进入运行时安装包。
资源来源、逐文件哈希和版权保留见该仓库的 `RESOURCE-MIGRATION.md` 与 `NOTICE`。

## 默认快捷键

| 按键 | 行为 |
| --- | --- |
| Meta+Left / Down / Up / Right | 焦点左 / 下 / 上 / 右 |
| Meta+F1 / F2 / F3 / F4 | 移动窗口左 / 下 / 上 / 右 |
| Meta+[ / ] | 缩窄 / 加宽 |
| Meta+F11 / F12 | 缩高 / 增高 |
| Meta+End / Home | 下一个 / 上一个窗口 |
| Meta+F / O | 当前 / 所有窗口切换浮动 |
| Meta+N / P | 下一个 / 上一个布局 |
| Meta+T / M | Tile / Monocle 布局 |
| Meta+S | 设为主窗口 |
| Meta+I / U | 增加 / 减少当前布局参数 |
| Meta+R / Y | 旋转布局 / 局部布局 |

Meta 为 Windows / Super 键。以上 25 个绑定只使用 Meta 与一个键，不需要
Alt、Ctrl 或 Shift，且互不重复；其余 14 个动作显式留空，清除历史绑定。
保留 Vicinae 的 `Meta+Space`、终端 `Meta+Return`、锁屏 `Meta+L`、显示桌面
`Meta+D`、Dolphin `Meta+E`、CopyQ `Meta+V` 与 Overview `Meta+W`。
Plasma 内建方向键快速平铺和 `Meta+T` 布局编辑器解绑，防止抢占 Krohnkite；
桌面 1–4 改为保留 `Ctrl+F1`–`Ctrl+F4`，`Meta+F1`–`Meta+F4` 用于移动窗口。
更改已写入快捷键文件的绑定后，需要重新登录 Plasma，清除已注册的旧快捷键。

## 生效与验证

更换源码包后在新的 Plasma 会话中生效；已运行重写版的设置更新使用上面的
`reconfigure`。避免反复关闭/开启脚本造成多个实例；当前 VM 的原地重启问题
仍按既有验证记录处理，新会话验收不等于原地重启已稳定。

```sh
nix eval --impure --json --file scripts/verify/krohnkite.nix
nix eval --impure --raw '.#nixosConfigurations."lvlv.os".config.system.build.toplevel.drvPath'
nix build --impure '.#nixosConfigurations.lvlv-vm.config.system.build.toplevel'
```

验证脚本覆盖默认关闭时 Home Manager 输出不变、profile 启用、显式关闭、
独立自定义及两台主机共享配置。
运行结果与 VM 验证证据记录在 [VALIDATION.md](VALIDATION.md)；实体机只求值，未部署。

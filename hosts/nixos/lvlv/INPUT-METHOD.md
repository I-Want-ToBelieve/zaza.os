# Tahoe 输入法与雾凇拼音

`lvlv` / `lvlv-vm` 的普通用户导入
`profiles/home-manager/gui/fcitx5-tahoe.nix`。
NixOS 在 `common.nix` 安装 Fcitx5 + fcitx5-rime，雾凇词库版本由现有
`flake.lock` 中的 nixpkgs 固定（当前 rime-ice 2026.06.30、librime 1.17.0、Lua 插件）。
没有复用其他主机的 Catppuccin 输入法配置，也没有安装其他 GUI 工具。

## 资源与配置

基础皮肤来自用户指定的
[Become-ILLUSORY/Fcitx5-MacOS-Theme](https://github.com/Become-ILLUSORY/Fcitx5-MacOS-Theme)，
固定参考提交 `ae1d3580042785c4fba9815cffa3cf153075e47d`。
修改后的两套资源随仓库保存于 `pkgs/fcitx5-tahoe/themes/`，保留 MIT 许可证，
由 Nix 构建成只读包；不运行安装脚本、不在登录时下载。

- Tahoe-Light / Tahoe-Dark 跟随 KDE 深浅色偏好。
- 横排九个候选，灰色较小序号与间距、系统蓝高亮、圆角半透明背景、阴影。
- 使用单独圆角遮罩请求背景模糊，阴影区域不纳入遮罩。
- 字体为已安装的 Noto Sans CJK SC；不是 macOS PingFang 的像素级字体复刻。
- KWin 模糊保持由已有的 Home Manager + plasma-manager 配置管理。
- Rime 的 `default.custom.yaml` 和 Fcitx5 配置由 Home Manager 声明。
- Rime 配置变更时，Home Manager 删除两个可再生成的 YAML 缓存并请求重新部署；
  避免 Nix store 的固定文件时间让 Rime 忽略新设置。离线更新时，下一次启动会重建
  缺失的配置缓存。词典二进制与用户词库保留。
- `~/.local/share/fcitx5/rime/build`、`*.userdb`、`user.yaml` 等保持可写。
  不对整个 Rime 用户目录建立只读链接，不清空用户词库。
- 当前 OpenCC 要求词典组带 `match_policy`，`rime-data.nix` 在构建时补上
  `short_circuit`，保留原先的优先匹配行为。

## 跨机器重建

全部输入法设置均有 Nix 声明来源：

| 内容 | 声明位置 |
| --- | --- |
| Fcitx5、Rime/Lua、雾凇词库、Noto CJK 字体 | `hosts/nixos/lvlv/common.nix` |
| 雾凇/OpenCC 兼容处理 | `pkgs/fcitx5-tahoe/rime-data.nix` |
| 固定皮肤资源与许可证 | `pkgs/fcitx5-tahoe/` |
| 输入法组、快捷键、深浅皮肤、Rime YAML、更新后的自动重新部署 | `profiles/home-manager/gui/fcitx5-tahoe.nix` |
| KWin 背景模糊 | `profiles/home-manager/desktop/mactahoe.nix` 的 plasma-manager 设置 |

版本跟随仓库的 `flake.lock`。用户配置路径使用 Home Manager 的 XDG 目录；
会话总线路径根据当前用户 UID 推导，不绑定 QEMU、固定 UID 或某台电脑的 home 路径。
新主机导入相同 NixOS / Home Manager 配置即可生成这些设置；硬件配置另按目标机器管理。
验证工作目录里的 SSH、截图、演示脚本仅用于验收，不是部署或登录依赖。
用户学习词频、自定义词库属于可写数据，换电脑时需要单独同步；重建不会清空它们。

## 操作

| 按键 | 行为 |
| --- | --- |
| Ctrl+Space | Fcitx5 输入法 / 英文键盘切换 |
| Caps Lock | 不触发 Rime 模式切换，不提交当前预编辑 |
| Space、1–9 | 选词 |
| Up / Down | Rime 默认的上一个 / 下一个候选 |
| Page Up / Page Down、- / = | 翻页 |
| Enter | Rime 原始编码上屏 |
| Escape | 取消当前预编辑 |
| F4 | Rime 方案与开关菜单 |
| Meta+Space | 保留 Vicinae |

Rime 的 `Caps_Lock` 显式设置为 `noop`，禁用此前的中英文切换与编码提交行为。
显式清空 Fcitx5 默认的 Shift 临时切换和 Meta+Space 输入法组切换，
避免前者绕过 Rime 的 Shift 配置，后者占用 Vicinae。Ctrl+Space 切换期间按 Rime 的
`CommitCommitPreview` 提交当前预览，避免配置值使用显示文案而被忽略。

## 验证与还原边界

2026-10-01 在现有 WHPX / VirGL QEMU 中构建并测试激活，没有重启 KWin、
Plasma 或虚拟机。测试通过后已保存为 VM 下次启动的默认配置。已有输入法配置备份于 VM 的
`~/.local/state/fcitx5/tahoe-backup-20261001/`。
此前运行系统固定于 `/nix/var/nix/gcroots/fcitx-tahoe-before-20261001`。

初版实测 Firefox 的 Wayland 原生输入：`nihao` 候选、空格上屏“你好”、
Page Down 翻到另一页候选。此前 Caps Lock 英文切换测试已作废，按用户要求禁用该行为。
后续验证单独按 Shift 前后 Fcitx5 状态均为 2（激活），候选窗保持可见；
运行时 D-Bus 配置确认备用触发键及两个输入法组快捷键均为空。
Home Manager 更新后，Rime 在不中断 Fcitx5 的情况下自动重新部署，九候选与序号间距生效。
Caps Lock 禁用后，独立 Rime 会话使用 VM 实际部署的配置与词典验证：
中文和英文模式均不切换，`ni hao` 预编辑与九个候选保持不变，没有提交编码。
修正已构建、激活并保存为 VM 下次启动配置。
构建与 lvlv / lvlv-vm 求值通过；输入声明检查通过；statix / deadnix 为 48 / 0。
合并后的最新仓库也已对 lvlv / lvlv-vm 求值通过；VM 运行的是输入法验证快照，
其他并发的桌面模块调整没有随本次输入法部署。
证据存放于 Windows 验证工作目录的 `artifacts/fcitx-tahoe-*.png`。

2026-10-03 已在整套桌面配置中构建并冷启动验收。锁定的 Fcitx5 5.1.22
通过 `pkgs/fcitx5-tahoe/engine.nix` 应用本地 ClassicUI 补丁，仅在 lvlv 使用。
`TahoeCandidateGrid=True` 启用右侧展开按钮，将当前页九候选排成三列；
点击同一按钮收起。鼠标选词、Page Up / Down 与原有数字 / 空格选词保留，
Down 继续是 Rime 的下一候选，不改动词库、学习数据或分页引擎。

`TahoeAnimations=True` 在 Wayland 候选显示和网格切换时启用 140ms 淡入；
隐藏仍即时完成。候选窗沿用 ClassicUI 的原生 Wayland 定位和缩放，
没有引入 Kimpanel 或另一个脱离光标位置的窗口。
125% 缩放下展开 / 收起 / 翻页 / 鼠标选词，以及 Qt、GTK、Firefox、
VS Code Electron 和 kitty 的“你好”上屏已通过。KDE MacTahoeDark / Light
切换时两套候选皮肤自动跟随，测试后恢复浅色。

这版仍未达到 macOS Tahoe 外观与交互的一比一验收，待补：

- 原生连续候选滚动、选中 / 隐藏动画与逐帧交互对照。
- Liquid Glass 折射、亮边与随背景改变材质；普通背景模糊不能等同。
- 原生字体指标、实际多屏及更多缩放组合。

完整集成、回退点和门户 / WHPX 限制见
[DESKTOP-ACCEPTANCE.md](DESKTOP-ACCEPTANCE.md)。

后续定制前端应继续使用同一 Rime 数据层，不替换雾凇词库与用户学习数据。

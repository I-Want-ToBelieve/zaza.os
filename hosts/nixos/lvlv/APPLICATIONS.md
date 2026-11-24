# lvlv.os 应用选择

范围：用户指定的 GUI，加上常用 CLI / TUI 与开发工具。只供 `lvlv.os` 和
`lvlv-vm` 使用，不导入仓库原有的大型应用套件。版本随仓库的 `flake.lock` 锁定。

## GUI

| 用途 | 应用 | 锁定版本 | 配置 |
| --- | --- | --- | --- |
| 发射器 | Vicinae | 0.29.0 | 使用包自带的用户服务，随图形会话启动 |
| 终端 | kitty | 0.49.0 | KDE 默认终端；Home Manager 管理字体与浅色配置 |
| 编辑器 | Microsoft VS Code | 1.139.1 | `pkgs.vscode`，使用 Wayland 与 KDE 原生标题栏；扩展按需安装 |
| 录制与直播 | OBS Studio | 32.2.2 | PipeWire / KDE 门户；未启用虚拟摄像头内核模块 |
| 浏览器 | Firefox | 156.0.1 | HTTP、HTTPS、HTML 默认应用；使用 KDE 窗口装饰 |
| 剪贴板 | CopyQ | 16.0.0 | 随图形会话启动，Qt Wayland 后端 |
| 截图与标注 | Flameshot | 14.0.0 | 使用 KDE Wayland 截图门户 |
| 局域网传输 | LocalSend | 1.18.0 | 允许 TCP / UDP 53317 |
| 中文输入 | Fcitx 5 | 5.1.22 | Wayland 前端和 Chinese Addons |
| 文件管理 | Dolphin | 26.08.1 | 由精简 Plasma 模块提供 |

版本来自锁定源码的完整 NixOS 求值，kitty 于 2026-09-30 核对，其他应用于
2026-09-29 核对实机与 VM 一致。用户因 Windows VirGL 上 Ghostty 着色器错误，
选择以 kitty 替换 Ghostty；两台 lvlv 配置均采用这一选择。
kitty 使用 C、Python 和 Go，采用 GPL-3.0；支持 GPU 渲染，外观可由纯文本配置管理。
来源：[kitty 官方仓库](https://github.com/kovidgoyal/kitty)、
[配置文档](https://sw.kovidgoyal.net/kitty/conf/)。

Vicinae 和 CopyQ 仅为 `i.want.to.believe` 启动。其他应用按需打开；
Plasma 的系统设置、钱包、门户、网络和音量等桌面组件仍保留。
不额外安装 Konsole、Ark、Spectacle、Discover、Elisa、Gwenview、Okular、Kate 等
可选 KDE 应用。依赖闭包与用户直接安装的应用清单不同。
MacTahoe 外观另外需要 Aurorae 装饰引擎、Qt 6 Kvantum 插件及主题资源，
由 Home Manager + plasma-manager 选择与管理，详见 [THEME.md](THEME.md)。

VS Code 是用户明确指定的 Microsoft 发行版，使用其产品许可证；Code - OSS 源码
的许可证不能等同于这个二进制发行版。其余工具的许可证和语言分析见本任务研究清单。

Firefox 每次启动通过 NixOS `Preferences` 策略将整数
`browser.tabs.inTitlebar` 设为 `0`，启用 KWin 标题栏，跟随 KDE 的窗口装饰主题与
按钮位置。Firefox 包装器还设置 `MOZ_GTK_TITLEBAR_DECORATION=system`，在 Wayland
下显式选择系统装饰，避免 GTK 自绘标题栏。此环境变量仅作用于 Firefox。
此项使用 `Status = "user"`，会覆盖旧 profile 的自绘标题栏设置，
仍可在当前会话中手动切换；下次启动恢复系统配置。标题栏会单独占用一行。
策略语义见 [Mozilla 管理员文档](https://firefox-admin-docs.mozilla.org/reference/policies/preferences/)。

Home Manager 激活时为普通用户合并 VS Code 设置
`window.titleBarStyle = "native"` 与 `window.customTitleBarVisibility = "never"`，
由 KWin 绘制 KDE 标题栏，避免出现额外的自绘标题栏。其他设置值保留，
`settings.json` 仍为可写文件；用户可在会话中修改，下次配置激活恢复这两项。
既有 JSONC 文件修改前备份为 `settings.json.before-kde-titlebar`，写回时使用
标准 JSON 格式，因此原注释保存在备份中。无法解析或为符号链接时拒绝覆盖。
此设置只供两台 lvlv 主机的 `i.want.to.believe` 使用，需完全退出 VS Code 后重新打开。
设置语义见 [VS Code 官方源码](https://github.com/microsoft/vscode/blob/main/src/vs/workbench/electron-browser/desktop.contribution.ts)。

## CLI / TUI

| 类别 | 工具 |
| --- | --- |
| Shell 与项目环境 | fish、direnv、nix-direnv |
| 文件、搜索、历史 | ripgrep、fd、fzf、bat、eza、zoxide、Atuin、zip、unzip |
| 结构化文本 | jq、yq-go、Miller |
| Git 与任务执行 | Git、Git LFS、delta、GitHub CLI、lazygit、just |
| 开发辅助 | nix-output-monitor、uv、Ruff、ShellCheck、shfmt、watchexec、hyperfine |
| 传输 | curl、wget、aria2、OpenSSH、rsync、rclone |
| 备份与加密 | restic、age、sops |
| 媒体 | FFmpeg、yt-dlp |
| 编辑和文件 TUI | Helix、Yazi |
| 会话管理 | tmux、Zellij |
| 监控、日志、磁盘 | btop、nvtop、ncdu、lnav |
| 系统与网络诊断 | fastfetch、pciutils、usbutils、smartmontools、iperf3 |
| Wayland 剪贴板管道 | wl-clipboard |

语言编译器、SDK 由项目自己的 Nix `devShell` 管理。Kubernetes、云平台、本地 AI、
容器服务和其他 GUI 不在此次清单中。Atuin 不自动创建账号或启用远程同步；
备份与传输工具不自动创建任务。

## 终端集成

- 默认登录 Shell：fish；默认终端编辑器：`hx`（Helix）。
- `z` / `zi`：zoxide 跳转目录；fzf 提供模糊搜索。
- `Ctrl+R`：Atuin 搜索历史；上方向键保留 fish 原有行为。
- `ll`：`eza -lah --group-directories-first`；`lt`：两层目录树；`lg`：lazygit。
- Git 使用 delta 分页、`zdiff3` 冲突展示，新仓库默认分支 `main`。
- direnv 接入 fish；项目仍需显式 `direnv allow`。
- JetBrains Mono Nerd Font 为终端图标提供字体；中英文字体沿用公共配置。

这些是系统默认值，用户自己的 KDE / MIME / Shell 设置可以覆盖它们。
QEMU 使用 NAT，无法用 VM 内的启动测试证明 LocalSend 的实体局域网发现、
OBS 的实体音频 / 硬件编码或实体显卡表现；实际验证范围见 [VALIDATION.md](VALIDATION.md)。
当前 VM 使用 WHPX + VirGL 原生 OpenGL，KWin 识别 RX 6750 XT，Flameshot 实际
截图已通过。早期 TCG / QPainter 下的失败及软件 OpenGL 试验记录仍保留在验证文档。

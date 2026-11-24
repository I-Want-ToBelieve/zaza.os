# lvlv.os 验证记录

日期：2026-09-29。验证源分支：`codex/lvlv-os-kde`。
开始前已在 `refactor/p1-baseline` 提交原有改动：`7237a50`。

## 依赖与环境

- 主 nixpkgs：`7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f`，Plasma **6.7.5**。
- 只更新 `flake.lock` 的根 nixpkgs 节点 `nixpkgs_6`，其余节点未改。
- 适配新 nixpkgs 的包名：将原有 `gcr` 引用改为 `gcr_3`；两者对应的版本均为
  **3.41.2**，属于兼容改名，没有切换到 GCR 4。
- GitHub archive 地址超时时，使用官方 codeload 下载同一提交，以 Nix 计算的
  `sha256-ZoxIApko70jCdbH3l20HWXOBaT2HZd87orzd2yJ9dVE=` 核对源码。
- 构建使用 USTC 的 Nix 二进制缓存镜像和官方缓存；保留 Nix 的签名验证。
  抽查同一 NAR 的哈希、大小和官方签名与官方缓存一致，没有新增信任密钥。
- Windows 10 Pro，QEMU 11.1.0；WHPX 组件禁用，因此本次明确选择 TCG，未修改
  Windows 功能或重启宿主。来宾 2 vCPU / 2 GiB RAM，临时 4 GiB swap 位于独立 overlay。
- VM 磁盘和 UEFI vars 独立；原 `zaza-vm-windows` 磁盘只作为只读 backing image。
  SSH `127.0.0.1:2224`、VNC `127.0.0.1:5912`，诊断 QMP `127.0.0.1:4446`。

## 已验证

| 项目                                              | 结果                                                                     |
| ------------------------------------------------- | ------------------------------------------------------------------------ |
| Windows 硬件只读扫描                              | 已完成，见 HARDWARE.md                                                   |
| Windows runner 参数、路径隔离、端口冲突、显式 TCG | 通过                                                                     |
| 新增/修改 Nix 模块语法与 Alejandra                | 通过                                                                     |
| 未声明 flake inputs                               | 通过                                                                     |
| Deadnix                                           | 通过，0 / 0                                                              |
| Statix                                            | 通过，48 / 48                                                            |
| `lvlv-vm` 完整系统求值                            | 通过                                                                     |
| `lvlv.os` 完整系统求值                            | 通过；预期提示实体磁盘标签尚未确认                                       |
| 既有 `zaza-vm-windows` 回归求值                   | 通过，使用更新后的锁定 nixpkgs                                           |
| Plasma / PIM / Qt 5 实际配置                      | 两台均为 6.7.5，PIM 和 Qt 5 集成关闭                                     |
| 应用范围                                          | Dolphin / Konsole / Ark / Spectacle / 系统设置保留，19 项可选 KDE 包排除 |
| VM 与实机隔离                                     | 仅 VM 自动登录和软件渲染；实机无这两项                                   |

完整 lint 棘轮通过，Statix / Deadnix 上限保持 **48 / 0**。将 `flake.nix` 中重复的
`checks.undeclared-inputs`、`checks.stellar-assets`、`checks.lint-ratchet` 合并为一个
`checks` 属性集，保留全部原有检查、脚本和注释，消除对应的 3 条重复键诊断。
成功输出保存在 guest 的 `/root/lvlv-results/lint-final.log`，并已取回本地任务 workspace
的 `artifacts/lvlv-lint-final.log`；其他日志和包清单位于 `artifacts/lvlv-*`。

最终 VM（包含启动动画超时修复）的系统 derivation：
`/nix/store/f9ci2l4x5hhf1qbppzhl5a4lgbc5p3zd-nixos-system-lvlv-vm-26.11.20260928.7a0f122.drv`。

附加的 `xiaoxin-pro14-2021` / `xiaoxin-pro16-2021` 回归求值未完成：前者遇到
固定输入 `srid/flake-root` 的 GitHub archive 下载失败（随后已用同提交源码校验并缓存，
尚未重跑），后者遇到既有 Hyprland 壁纸的 `raw.githubusercontent.com` 连接重置。
这两项不计为通过。本次也没有运行完整的 `nix flake check` 或构建所有旧主机。

## 构建与启动

`lvlv-vm` 系统构建已成功（退出码 0），最终系统为：

```text
/nix/store/grifrn3pym7piaxrqj2rjf16x8drv306-nixos-system-lvlv-vm-26.11.20260928.7a0f122
```

`dry-activate` 与 `boot` 均成功。重启隔离来宾后，`/run/current-system` 与上述构建
输出一致，主机名为 `lvlv-vm`。实际完成以下检查：

- SDDM 自动登录到 KDE **Wayland** 会话，`plasmashell --version` 返回 **6.7.5**。
- KWin、Plasma Shell、NetworkManager、PipeWire 和打开的 Konsole 均处于 active，
  Fcitx5 进程也已自动启动。
- 桌面壁纸、面板、系统托盘及 Konsole 窗口可见，已保存 QEMU 截图
  `artifacts/lvlv-desktop.png`。
- NetworkManager 报告 `connected / full`；系统级、用户级失败服务均为 0。
- Dolphin、Konsole、Ark、Spectacle、系统设置的可执行文件存在；Elisa、Gwenview、
  Okular、Kate、Discover、QRca 不在系统命令路径中。
- 原 backing 磁盘的长度和修改时间与启动前一致。

首次 TCG 启动的 `plasma-ksplash.service` 达到上游默认 **40 秒**超时，随后出现
KSplash D-Bus 注册等待超时。已仅为 VM 添加 systemd drop-in，保留上游启动命令，
将超时放宽为 **5 分钟**；实机不继承该设置。首次启动日志保留在
`artifacts/lvlv-runtime-splash-note.txt`。
最终重启复验显示动画 `Result=success`、`ExecMainStatus=0`，已正常退出，用户级
失败服务为 0；修复后的结果见 `artifacts/lvlv-runtime-splash-final.txt`。
额外的 `QT_QPA_PLATFORM=offscreen` 版本探测曾使独立探测进程崩溃；改为连接真实
Wayland 显示后查询成功，运行中的 Plasma Shell 未受影响。

最终修复构建日志见 `artifacts/lvlv-build-splash-fix.log`，初次构建的最后阶段见
`artifacts/lvlv-build-final.log`；前一阶段因调整缓存和并行度
由操作者中断后续跑，不能把中间日志的中断当作最终构建失败。

当前验证磁盘位于本地任务 workspace 的 `state/lvlv-vm`，VM 保持运行，VNC 地址为
`127.0.0.1:5912`。停止后可在 Windows 从仓库根目录启动同一状态：

```powershell
./scripts/vm/windows/run.ps1 run -VmName lvlv-vm -Graphics Vnc -SoftwareEmulation -MemoryMiB 2048 -Cpus 2 -State C:/Users/iwantobelieve/Documents/ChatGPT/nixos/state/lvlv-vm
```

这验证了既有隔离磁盘上的系统构建、启动与桌面，未演练从空白磁盘安装，也未验证
实体音频输出或中文输入法交互。

## 实机范围

没有在这台电脑的实体 SSD 上安装、分区或格式化。挂载标签仍需实际安装环境确认。
QEMU 无法代替 AMD GPU、Wi-Fi 7、蓝牙、板载声音及睡眠恢复的实体测试。
本次 TCG 验证也不代表 WHPX 加速已可用。

## 后续应用安装与验证

用户随后选择了 Vicinae、Ghostty、Microsoft VS Code、OBS、Firefox、CopyQ、
Flameshot、LocalSend、Fcitx 5、Dolphin、fish 和常用 CLI / TUI 开发工具。
配置清单见 [APPLICATIONS.md](APPLICATIONS.md)。本节对应的变更已完成 Nix
求值、构建、激活与 VM 重启；上文结果属于加入这些应用之前的基础 Plasma 系统。
因此上文 Konsole / Ark / Spectacle 的存在性检查不是新应用清单的通过证据。

新增的应用模块通过 Alejandra、未声明输入检查及 Statix / Deadnix **48 / 0**
棘轮。实机与 VM 完整系统求值均通过，所选版本一致；两台机器均保留 Dolphin，
排除 22 项可选 KDE 包（新增 Konsole、Ark、Spectacle）。LocalSend 的 TCP / UDP
53317 已进入防火墙配置，Vicinae 和 CopyQ 已进入图形会话自启动目标。

本次构建使用既有来宾的 2 GiB RAM，以及 overlay 内的 4 GiB 临时 swap。
Nix 报告新增缓存下载约 1.3 GiB、解包约 4.6 GiB；另由固定输出 derivation 从
微软官方地址下载 VS Code 1.139.1。原系统已用 GC root 保留。

应用系统 derivation：
`/nix/store/wkxlnhibxv0h350wd7ash4whva0awp4j-nixos-system-lvlv-vm-26.11.20260928.7a0f122.drv`。
系统输出：
`/nix/store/hdbbc871wc8wc2lkj84ry97g4m283528-nixos-system-lvlv-vm-26.11.20260928.7a0f122`。
`dry-activate`、`test`、`boot` 均成功，重启后的 `/run/current-system` 与此一致。

已完成的应用检查：

- GUI 和终端工具的命令全部存在，Konsole、Ark、Spectacle 等排除项不在系统命令路径中。
- fish 的 zoxide、fzf、Atuin（Ctrl+R）、direnv 集成和别名可用，`EDITOR=hx`。
  ripgrep / fd 文件搜索、fzf 过滤、jq JSON 读取、age 加解密往返均通过。
- Firefox / Dolphin MIME 默认值、Ghostty 默认终端及全部所选 GUI 桌面入口正确。
- 重启后 Plasma Wayland、PipeWire、Fcitx5、Vicinae、CopyQ 正常运行，首次完整
  检查的系统级及用户级失败服务均为 0。
- Ghostty 显示 fish 提示符，VS Code 显示欢迎界面，OBS 显示主窗口及初次配置向导，
  LocalSend 显示收件界面，Flameshot 显示设置窗口，Vicinae 显示初次设置向导。
- 恢复声明式 QPainter 桌面后，Firefox 正常显示浏览器窗口，Dolphin 正常列出用户主目录。
- OBS 识别到 PipeWire 的虚拟音频输出；LocalSend 实际监听 TCP / UDP 53317。
- `wl-copy` / `wl-paste` 往返通过，CopyQ 自动捕获同一测试文本。

日志位于本地任务 workspace 的 `artifacts/lvlv-apps-*`，包括完整构建、激活、求值、
lint、CLI、剪贴板及应用启动记录；对应 PNG 保存了实际可见窗口。
VS Code 的命令启动器需要 `--wait` 才能由测试用的临时 systemd 服务保持窗口。
强制停止该测试服务时曾留下一个 Code coredump；不能据此宣称所有应用退出路径已验证。
图形试验及退出过程中也出现过 DrKonqi coredump 处理单元失败，诊断日志已保存。
撤除临时覆盖后再次重启，最终健康检查确认当前系统输出一致、QPainter 后端恢复，
系统级和用户级失败服务均为 **0**，Plasma、PipeWire、Vicinae、CopyQ、Fcitx5 正常。
最终记录为 `artifacts/lvlv-apps-final-health.txt`；在当前 2 GiB 来宾中重新启用了
既有的 4 GiB 临时 swap。实体磁盘未改，原 backing image 的长度和修改时间保持不变。

### Flameshot 与 TCG 图形限制

默认 VM 的 `KWIN_COMPOSE=Q` 使用 QPainter。Flameshot 设置窗口可以打开，但
其 KDE Wayland 截图请求返回 `ScreenShot2.Error.Cancelled`。
已核对截图门户许可为 `yes`、会话未锁定；
[KWin 6.7.5 截图源码](https://raw.githubusercontent.com/KDE/kwin/v6.7.5/src/plugins/screenshot/screenshot.cpp)
在没有 EGL/OpenGL 后端时直接不生成图像，因此这不是缺装截图门户。

VM 内临时覆盖为 `KWIN_COMPOSE=O2` 后，实际后端为 Mesa llvmpipe OpenGL 4.6，
Flameshot 成功保存 `/tmp/lvlv-flameshot-test.png`，已取回为
`artifacts/lvlv-flameshot-captured.png`。但该 TCG / 非 GL virtio-vga 环境中
Plasma 的壁纸与面板未正常显示；改用 Qt Quick 软件后端也未解决。
两份临时用户服务覆盖已撤除，VM 恢复声明式 QPainter 配置。
没有把未通过完整桌面验证的 OpenGL 试验写入主机配置。

因此，**默认 TCG VM 下的 Flameshot 实际截图仍受限**，不能把临时 OpenGL 截图
成功描述为默认 VM 全部通过。实机不设置 `KWIN_COMPOSE` 或
`LIBGL_ALWAYS_SOFTWARE`，AMD GPU 下的截图、屏幕共享和录制仍需实机确认。
本次也没有验证 LocalSend 跨设备发现/传输、OBS 硬件编码/实体音频、中文输入交互、
各个 CLI 工具的全部功能或应用账号登录。各应用的个人化初次向导保留给用户选择。

## MacTahoe / Home Manager（2026-09-30）

根据用户要求，新增 Home Manager + plasma-manager 的 MacTahoe 外观配置。
范围与入口见 [THEME.md](THEME.md)，仅用于 `lvlv` / `lvlv-vm` 的普通用户。
新增依赖由 `flake.lock` 固定，旧依赖节点逐项比较无变化：

- MacTahoe-kde：`cbf6a1f71b591d143184855d62f6272ce533e7c3`。
- MacTahoe-icon-theme：`839848b9a8a38a92a6936e30c4abe35cc6f2546d`。
- plasma-manager：`a19a2a029fa180911bd89c554dca1616e10f4c1d`，跟随现有 nixpkgs / Home Manager。

VM 与实体主机完整配置求值通过；Alejandra、未声明输入检查和 Statix / Deadnix
**48 / 0** 通过。Aurorae 从精简桌面的排除列表中恢复，用于 MacTahoe 装饰；
新增 Qt 6 Kvantum 引擎，不启用 Qt 5 集成。

最终 VM derivation：
`/nix/store/nxqp2hww3davyzdcf824arvi63j3r5gw-nixos-system-lvlv-vm-26.11.20260928.7a0f122.drv`。
系统输出：
`/nix/store/9p4vyaxbdhm8nfs7yx1hj5y3hp461yn7-nixos-system-lvlv-vm-26.11.20260928.7a0f122`。
实体机仅求值，没有安装；其 derivation 为
`/nix/store/p9nf6k76i0wqhv66458p51ysmgqpp2ki-nixos-system-lvlv-26.11.20260928.7a0f122.drv`。

构建、`dry-activate`、`test`、`boot` 均成功。旧系统保留在
`/nix/var/nix/gcroots/lvlv-before-tahoe`；旧用户配置备份在 VM 内
`/root/lvlv-results/before-tahoe-config.tar.gz`。激活时修复了此前图形测试留下的
两个 root 所有目录：`~/.config/systemd` 与 `~/.config/systemd/user`，恢复普通用户
所有权后 Home Manager 服务成功；没有添加全局递归 chown 的配置。

打包时显式向图标安装脚本传入 `--name MacTahoe`，避免它读取 stdenv 的 `name`
变量而生成错误目录。包只含主题资源，跳过不必要的 ELF / shebang 修复。
两次中间构建被主动停止，实际通过状态以最终 `artifacts/lvlv-tahoe-build.exit` 为准。

KDE GTK 桥接在登录时会重写 `~/.gtkrc-2.0`，导致重复激活与现有 `.homebak`
备份冲突。使用 Home Manager 的 `gtk.gtk2.force = true` 声明该文件由 HM 管理；
初次备份仍保留，修复后激活成功。没有使用全局强制覆盖。

第一次 TCG 登录时 Plasma D-Bus 未及时响应，导致面板脚本超时。VM 现通过
plasma-manager 的 `startup.startupScript` 在主题选择后、面板创建前等待桌面就绪；
面板和壁纸脚本使用局部 `qdbus` 函数，经 `busctl` 直接调用已知的 `evaluateScript`
接口，超时 120 秒，避免 qdbus 自身的接口探测超时。布局 JavaScript 与执行标记仍由
plasma-manager 生成，保留其面板配置清理行为。只在 VM 中使用该适配。
关闭 VM 的自动息屏与挂起，方便 VNC 检查。顶部栏按主题实际最小高度配置为 32px，
底部 Dock 为 64px。这些 VM 调整不作用于实体主机。

交互试验中 KWin 6.7.5 / QPainter 在窗口关闭或重配时发生过崩溃，栈指向
`ItemRendererQPainter::renderSurfaceItem` 内的 Qt 光栅图像混合。临时关闭 Qt AVX2
优化仍复现，相关试验覆盖已撤除，没有将它写入仓库；Breeze 装饰隔离试验也未解决。
诊断日志为 `artifacts/lvlv-tahoe-qpainter-crash-*.log` 与
`artifacts/lvlv-tahoe-render-trial-crash.log`。这与配置成功构建是两个独立结论，
不能将构建、主题组件已显示描述为所有图形交互均已通过。

最终的直接 D-Bus 适配已通过重置执行标记后的完整冷启动：主题、两条面板、壁纸
均自动执行并写入成功标记，无需手动重跑。日志为 `artifacts/lvlv-tahoe-cold-startup.log`。
GTK2 修复后的 Home Manager 登录后重复激活也通过，见 `tahoe-repeat-activation.log`。

但完整冷启动后，以及完全结束旧用户会话再登录后的交互试验，QPainter 绘制崩溃
仍可复现。额外测试关闭 Kvantum 窗口半透明 / 模糊，同样在打开 Dolphin 时崩溃；
记录为 `artifacts/lvlv-tahoe-opaque-trial-crash.log`。该试验主题和全部临时覆盖已撤除，
VM 恢复仓库声明的 `MacTahoe`。**本轮图形交互验证未通过**；构建、激活及自动布局
通过不代表桌面稳定性通过。当前非 GL QEMU / QPainter 环境不能作为完整 Tahoe
图形效果与稳定性的最终验收环境，实机 GPU 的 OpenGL 路径尚未验证。

## WHPX / 原生 VirGL 与 kitty（2026-09-30）

用户启用 WHPX 后已重启 Windows。实际宿主为 Windows 10 Pro 22H2、
Ryzen 7 9800X3D、Radeon RX 6750 XT，`HypervisorPresent=true`。
此前开启的是 `HypervisorPlatform`，并将当前启动项 `hypervisorlaunchtype`
从 Off 改为 Auto；VirtualMachinePlatform 原本已开启。本轮没有修改 GPU 驱动
或 Windows 安全设置。WHPX 的独立初始化探测及 VM 冷启动均通过。

仍使用隔离的 `state/lvlv-vm/lvlv-vm.qcow2` overlay 与独立 UEFI vars，
原 backing image 的长度和修改时间保持不变。未安装到物理磁盘。
当前启动使用 Scoop QEMU 11.1.0，4 vCPU / 6144 MiB，`q35`、`-accel whpx`、
`virtio-vga-gl`、`-display sdl,gl=on`、进程变量 `SDL_OPENGL_ES_DRIVER=0`。
SSH / QMP 仅监听本机回环端口 2224 / 4446；Native 模式不监听 VNC。

### 启动卡死与限制

同一原生 SDL/GL 路径带 `usb-tablet` 时，在图形启动前令整个 VM 和 QMP 失去响应。
改 `pic=off`、GL core profile、非 VGA VirtIO GPU、单 vCPU 或撤销来宾 QPainter
都未解决。最终省略 USB tablet、保留标准 PS/2 鼠标后，冷启动成功，SSH / QMP 正常。
启动器现为所有 SDL 模式省略 tablet，VNC/headless 仍保留绝对坐标输入。
SDL 可用 `Ctrl+Alt+G` 捕获或释放输入。
[WINQ-EMU QEMU](https://github.com/cmspam/winq-emu-qemu) 也记录了 Windows SDL
鼠标模式切换冻结的修复；本机结果与这个方向一致，尚未用调试栈证明完整根因。
本次未安装这个分支。另一个隔离下载的 QEMU 10.0.50 VirGL 构建在本机发生
WHPX MMIO 错误，已弃用，未替换 Scoop 安装。

**原地来宾重启仍未通过**：关闭阶段已显示文件系统卸载和 System Reboot，随后
QEMU / QMP 卡住。`-no-reboot` 试验同样无效，已撤除。保留两次失败日志，
仅在确认测试进程身份后终止它，再冷启动。不能把冷启动成功等同于原地重启稳定。
ANGLE 路径也未通过当前宿主的完整启动检查。

### 最终声明与验证

VM 默认撤销全局 `KWIN_COMPOSE=Q` / `LIBGL_ALWAYS_SOFTWARE`，KWin 自行使用 EGL。
旧 QPainter 配置移到 VM 的 `software-rendering` specialisation，作为非 GL 恢复入口；
此前的 QPainter 交互崩溃记录仍有效。VM 增加 mesa-demos 供渲染诊断，实体机不增加它。

Ghostty 1.3.1 在此 Windows VirGL 上启动进程后发生 `std430` 着色器编译错误。
仅 Ghostty 使用软件渲染的临时试验可以显示终端，但用户随后明确要求换成 kitty。
最终 `lvlv.os` 与 `lvlv-vm` 均移除 Ghostty，采用 kitty **0.49.0**，默认终端、
KDE desktop entry 和 Dock 同步更新。Home Manager 管理 kitty 的浅色配色、
JetBrains Mono Nerd Font 和蓝色光标；没有保留 Ghostty 的兼容包装器。

最终 VM derivation：
`/nix/store/f44s0x7vrxlsip11dj5pxh78wr6l3d73-nixos-system-lvlv-vm-26.11.20260928.7a0f122.drv`。
系统输出：
`/nix/store/cm8xxsisb25rjsyr0c8wwml398hg9kkr-nixos-system-lvlv-vm-26.11.20260928.7a0f122`。
实体机仅求值，通过的 derivation：
`/nix/store/dfx71qc7gxxgv3jbf69iqa8k2lw7qdbg-nixos-system-lvlv-26.11.20260928.7a0f122.drv`。

最终系统构建退出码 0；`dry-activate`、`test`、`boot` 和 Home Manager 激活通过。
旧系统保留在 `lvlv-before-virgl` 与 `lvlv-before-kitty` GC roots。
最终 Nix 文件 Alejandra 检查、全仓 Statix / Deadnix **48 / 0**、Windows runner
参数测试通过；测试覆盖 SDL 无 USB tablet、VNC 保留 tablet、WHPX 无自动 TCG 回退。

冷启动后的实际检查：

- KWin：Wayland、OpenGL / EGL、Mesa 26.2.3、OpenGL 4.3，渲染器
  `virgl (AMD Radeon RX 6750 XT)`；glxinfo 报告 `Accelerated: yes`。
- MacTahoe Aurorae、壁纸、顶部 32px 与底部 64px 面板正常，plasma-manager 执行标记存在。
- kitty 窗口及 fish 提示符可见，默认 `TERMINAL=kitty`；当前 system profile 无 Ghostty。
- Dolphin 窗口正常显示，Flameshot 通过 KDE 门户保存实际截图。
- 当前运行检查中 KWin `NRestarts=0`，系统与用户失败服务均为 0，当前 boot 无 coredumps。

证据保存在任务 workspace 的 `artifacts/lvlv-kitty-*`、`lvlv-virgl-native-*`、
`lvlv-whpx-native-warm-reboot-*` 与 `lvlv-whpx-native-no-reboot-failed-*`。
这些检查证明本机原生 GPU 渲染与冷启动可用，不能替代长期稳定性、Vulkan、
OBS 硬件编码、实体机驱动和物理磁盘布局验证。

## 最新集成桌面验收（2026-10-03）

最新组合构建、激活、冷启动、统一快捷键和跨应用输入结果见
[DESKTOP-ACCEPTANCE.md](DESKTOP-ACCEPTANCE.md)。它包含本轮未通过的
OBS / 浏览器屏幕选择器、交互截图与 WHPX 关机 / 原地重启项目。
下面各节的旧系统输出保留作为历史记录，当前结果以集成验收为准。

## Krohnkite Meta 单修饰键（2026-10-04，当前）

独立源码提交 `120ef471b4c37fa540e15693843df033254b64b9` 将 25 个默认绑定改为
`Meta + 单个键`，不使用 Alt、Ctrl 或 Shift；其余 14 个动作保持未绑定。
QML 与两台主机共享 profile 的 39 个 action 名称和按键逐项一致。Nix profile
显式写入全部 39 项，避免遗留旧绑定；Plasma QuickTile 四个方向和 Edit Tiles
解绑，桌面 1–4 保留 Ctrl+F1–F4。启动器、终端、锁屏及显示桌面的按键保留。
完整映射见 [TILING.md](TILING.md)。

Windows `pnpm check`（关闭 Nx daemon）和 `pnpm release:assets` 均退出 0；
发布资产校验验证 39 个唯一 action、25 个唯一 Meta 默认绑定及离线源码重包。
`.kwinscript` SHA-256 为
`1ac77924caebce44ee21932aec627b0cff9b9b4e569f1debbe9abbbc322dcd16`。
JavaScript bundle 与前一轮逐字节一致，SHA-256 仍为 `4ce08863...`。
两主机配置求值、Alejandra、未声明 input、96 文件源码清单、Statix/Deadnix
48/0、Linux 构建、Qt 检查及隔离 KWin 文件配置 smoke 均通过。

- VM 系统：`/nix/store/6jd0q95m4g2jm4n3hy8r0i1bqdp9vps7-nixos-system-lvlv-vm-26.11.20260928.7a0f122`。
- VM derivation：`/nix/store/l3yfzghjip90h0zwbvxjacr9c5r9n7n8-nixos-system-lvlv-vm-26.11.20260928.7a0f122.drv`。
- 实体机仅求值：`/nix/store/kl5gqr5qasvc2c25j6cwzpyh9k59v27l-nixos-system-lvlv-26.11.20260928.7a0f122.drv`。
- 新包：`/nix/store/3gzrqf3bfdpv6b7jf14ynq579mgghx8y-krohnkite-effect-1.0.0`。
- 干净登录：`2026-10-04T07:55:10-06:00`，完成 dry-activate、test、profile 和 boot。

真实会话的 KGlobalAccel `allShortcutInfos` 核对了全部 39 项；25 个绑定只有
Meta，14 个禁用动作对应空序列（Qt 键码 0），未发现同组或其他组件冲突。
OS 的 runtime verifier 同时确认 Krohnkite 绑定数 25、零冲突、零缺失、零额外
修饰键。随后通过 QMP 只发送 `meta_l+m` 和 `meta_l+t`，没有 Alt/Ctrl/Shift：

| 阶段 | 窗口 1 `(x,y,width,height)` | 窗口 2 `(x,y,width,height)` | maximizeMode |
| --- | --- | --- | --- |
| 默认 Tile，间距 8 | `(8,40,756,816.4)` | `(772,40,756,816.4)` | 0 |
| Meta+M | `(8,40,1520,816.4)` | `(8,40,1520,816.4)` | 3 |
| Meta+T | `(8,40,756,816.4)` | `(772,40,756,816.4)` | 0 |
| 文件重载，间距 16 | `(16,48,744,800.4)` | `(776,48,744,800.4)` | 0 |

验收 `shortcutInputMode=qmp`、`forceInitialTile=false`，KWin wrapper PID
34802 与实际 compositor PID 34807 前后相同，`NRestarts=0`，清理错误和失败
系统单元均为空。结果保存在 `/root/krohnkite-effect-live-results-1791122296-36110/`，
本地任务 workspace 的 `artifacts/krohnkite-meta/` 保存注册键码、配置求值、
几何、日志和构建记录。独立 flake check 也通过。缓存站连接暂时失败时使用了
已缓存依赖进行离线构建，没有降低 TLS 或签名验证。
上述验收当时尚未冷启动；实体机未部署。OS 仓库的既有混合暂存区保持不变。

用户随后要求打开桌面查看。旧隐藏 Native 来宾已到达 System Power Off，
但 WHPX 宿主进程和 QMP 挂住，核对 VM 身份并归档日志后结束旧进程。
可见 Native 实例在启动 NetworkManager 时停住，SDL 窗口未响应，SSH 无 banner；
没有将此现象归因于 Krohnkite。改用同一磁盘、8 GiB、默认 WHPX/q35、非 GL
virtio-vga 与 loopback VNC 后，`6jd0q95m...` 系统完成冷启动。
Plasma/KWin 为 active，wrapper PID 886、Shell PID 1016，用户失败单元为空。
Krohnkite `isScriptLoaded` 为 true；两个保留供用户查看的预览终端自动左右平铺。
TigerVNC 查看器已打开。原生 framebuffer 画面保存在任务 workspace 的
`artifacts/lvlv-current-preview.png`；此前 Native 会话的 Meta 键盘验收记录继续保留。
这次证明 VNC 显示模式的冷启动与平铺，不能作为可见 Native 显示模式冷启动通过。

## Effect v4 Krohnkite 源码包替换（2026-10-04，前一轮）

本轮 lvlv profile 选择独立 Krohnkite flake input 的源码构建包，替换两台主机
原来的 nixpkgs 稳定包。独立项目以 Effect v4 / TypeScript monorepo 重写运行逻辑，
保留 KWin 插件 ID、原生设置和所需上游 QML 资源。
包选择、文件配置、会话切换和原图片用途见 [TILING.md](TILING.md)。
下面 2026-10-01 的稳定包结果不能视为本轮源码包通过的证据。

已完成的只读基线核对：VM 的 `/root/desktop-integration-source` 与当时 canonical
仓库选定的 55 个公开关键文件 SHA-256 全部一致，包含 flake/lock、两台主机共用
配置、Krohnkite module/profile、MacTahoe 与 Fcitx 的配置和资源。
基线核对时的运行、冷启动及 system profile 都指向：

```text
/nix/store/l3m5h6vmi1ag0vgwpwhwkkc12v18d2s5-nixos-system-lvlv-vm-26.11.20260928.7a0f122
```

对应 deriver 为
`/nix/store/syqkqgq0h29a2zdzvsbcsg10j3l88cg3-nixos-system-lvlv-vm-26.11.20260928.7a0f122.drv`，
与 `/root/desktop-integration-results/lvlv-vm.drv`、`system.txt` 和
`coldboot-system.txt` 一致；该历史集成构建的 `build.exit`、`activation.exit` 均为 0。
本轮从此基线增补公开的 Krohnkite input/module/profile 变更。
这次只读核对确认的是变更前基线；下面记录新的源码包构建与激活结果。
摘要保存在任务 workspace 的 `artifacts/lvlv-krohnkite-baseline-summary.json`，
公开文件哈希清单为 `artifacts/lvlv-krohnkite-public-source-hashes.json`。

| 本轮检查 | 状态 |
| --- | --- |
| 新输入相对路径锁定、既有锁定节点保持及未声明输入检查 | 通过；仅新增 Krohnkite 节点与根输入引用，跟随原 nixpkgs |
| 源码快照 SHA-256 清单与排除项检查 | 通过；最终 95 个公开文件，无源码子模块、依赖目录、预编译 dist 或私密文件，来源以当前 SOURCE.json 为准 |
| 默认关闭、lvlv profile 选包、覆盖与两台主机共用配置的独立模块检查 | 通过；未启用模块的 activation derivation 不变，两台选择同一 1.0.0 包 |
| `lvlv.os` / `lvlv-vm` 完整配置求值 | 通过；实体机只求值，没有部署 |
| 最终源码的 Windows 检查与本地发布资产 | 通过；`pnpm check`、五包构建及资产校验通过 |
| 最终 Nix 依赖预取完整性 | 通过；420/420 包及 17 个原生平台 manifest 检查通过 |
| 最终 Nix 源码包构建、离线类型检查与测试 | 通过；k32brf86...，Linux 实际执行 329 项测试，bundle 与 Windows 相同 |
| 最终安装包的真正 Qt 检查 | 通过；350477 字节、4ce08863...，部分最大化、内部窗口、39 快捷键 / 12 原生窗口及清理检查全部通过 |
| 历史独立 Krohnkite Nix 源码包构建、离线类型检查与测试 | 通过；初次 312 项，历史 hfga 包 318 项测试通过 |
| 初次包的两窗 Qt 运行时兼容检查 | 通过；历史结果，不覆盖新增压力用例 |
| 历史 hfga 包的 39 快捷键 / 12 原生窗口 Qt 压力检查 | 未通过；Qt 6.11.2 在同步启动期间 SIGSEGV，阻止该系统激活 |
| 历史 hfga 包的隔离 KWin 文件配置检查 | 通过；8 → 16 间距、非法值/缺键回退及恢复均实际验证 |
| Alejandra、未声明输入、Statix / Deadnix 棘轮 | 通过；上限保持 48 / 0 |
| 初次 VM 完整系统构建及第二次激活 | 通过；dry-activate、test、system profile、boot 与 Home Manager 激活成功 |
| 历史同步策略包的 VM 完整系统构建 | 通过；j5kn1a1h... 已构建，因该包 Qt 压力失败未激活 |
| 最终 VM 系统构建、激活与新会话 | 通过；sacpcjp2...，dry-activate、test、profile、boot 及单一干净 Plasma 登录完成 |
| 历史已激活版本的 Plasma 单一会话加载源码包 | 已看到启动消息与正确脚本链接；不计为最新包的生产行为通过 |
| 最终常规会话窗口平铺、快捷键及 `kwinrc` + `reconfigure` 重载 canary | 通过；默认 Tile、Monocle、返回 Tile、8 → 16 间距四阶段几何通过，实际 compositor PID 保持不变 |
| 最终验收的清理与系统健康 | 通过；cleanupErrors=[]，基线/最终/新增失败系统单元均为空，NRestarts=0 |
| 历史干净会话的用户服务健康 | 通过；当时用户失败单元为空，四个桌面辅助服务 active；最终包结果见本表与下文 |

`scripts/verify/krohnkite.nix` 已实际求值：`inactive.unchanged=true`，
默认关闭、profile 启用、显式关闭和独立自定义均符合预期。自定义间距为 12，
`KrohnkiteToggleFloat=""` 可取消该动作的绑定；实体机与 VM 的 package、settings、
shortcuts 相同，包版本为 1.0.0。输出保存于任务 workspace 的
`artifacts/krohnkite-flake-module-eval.json`。

本轮输入是仓库内的 `path:./inputs/krohnkite`。相对路径 lock 节点没有内容
`narHash`；真正用于复现源码的是 zaza.os Git 提交中的快照和 `SOURCE.json`
逐文件 SHA-256 清单。本轮初次清单基准提交为 `480dc0d96a4f97137514a57423157fbe23fa1ca2`，
后续源码提交或快照更新需运行 `scripts/update-krohnkite-source.py`，
同步更新清单并检查输入，更新后以当前 `SOURCE.json` 为准。
不得用 lock 中的路径记录代替快照内容校验。

初次构建产物（历史）：

```text
/nix/store/jmbzxb6kk8a0h41gh8z9hl54av1rl5jl-krohnkite-effect-1.0.0
/nix/store/4zg89x1c76jgl1pjj7p7dxwgsvc9v5jy-krohnkite-qt-runtime
/nix/store/81qy1459r47fw8szfqmfcz1gbdkb6jk1-nixos-system-lvlv-vm-26.11.20260928.7a0f122
```

VM derivation 的 store 哈希为 `sapqxbkkdpg6z9yqp6v2aqij6ypgchi1`；
实体机 `lvlv.os` 求值的 derivation store 哈希为 `0wj43z25ymd4xiwcb3y5c46aqhjn11sc`。
实体机没有构建或部署。第二次激活后的 system profile 与新 VM 输出一致；
初次激活阶段没有实际冷重启，`boot` 成功表示更新启动配置，不能描述为该阶段
已完成冷启动验证。

历史同步策略修复加入 Effect 同步边界的调度配置，Nix 离线类型检查和 **318 项**测试通过。
包与系统已构建：

```text
/nix/store/hfga4rb85019j2n1cx582fjyvsipg34n-krohnkite-effect-1.0.0
/nix/store/j5kn1a1h8cdizdligzly2m3grj2q1631-nixos-system-lvlv-vm-26.11.20260928.7a0f122
```

该历史 JavaScript 为 **328018 字节**，SHA-256 为
`a7fd8c08be5f0f289c1b25d2d663ad1dd0ad2373a3655c8fff3b81f0e18b885b`。
该包在独立 KWin 中完成 `kwinrc` / `reconfigure` 文件配置检查：间距 8 → 16、
非法值及缺键回退、原配置恢复均通过，证据见任务 workspace 的
`artifacts/krohnkite-followup-kwin.log`。
新增 Qt 压力 fixture 注册 39 个原生快捷键信号和 12 个原生窗口（11 个初始，
第 12 个通过 windowAdded），在同步启动阶段发生 SIGSEGV。
独立 offscreen GDB 栈落在 QV4 自动 GC 的 `MarkStack::drain`；根因仍在诊断。
这项历史检查未通过，**j5kn1a1h... 系统没有激活**；当时运行基线为上面的
`81qy1459...`。包构建成功和隔离文件配置通过不能代替压力检查或生产验收。

随后正式构建将 Qt 资产中的生成器转换为普通 JavaScript 状态机。
中间 bundle 为 349456 字节、SHA-256 为
`326db75651ee06e30c052babedf92b8f2d0de9af1baf7cbef691da8d91e321ad`，
已通过完整原生 Qt 压力用例。补充 QML realm 数组配置解码回归后的中间 bundle
为 **350087 字节**，SHA-256 为
`691f121f97b5730176c89fdbec0f696e1d4de75a6642b0ce9a6949ccf4b19870`。
该版本在 Windows 目标仓库执行 `pnpm check`，**327 项**测试、五包构建与本地
发布资产生成和校验通过；同一稳定的 39 原生快捷键信号 / 12 原生窗口 Qt 6.11.2
fixture 在默认环境中退出 0，保留 GC、布局切换、配置重载、Scope 清理与迟到
信号门禁的全部断言。证据在任务 workspace 的
`artifacts/krohnkite-final-lowered-qt-result.txt`。
该 327 项中间版本后来在真实会话中暴露了部分最大化轴还原及内部通知误作第三窗
的问题；它的通过记录不代替下面最终版本的验收。

最终版本修复这两项行为。Linux Nix 构建实际执行 **329 项**测试，Windows
`pnpm check` 与本地发布资产校验通过；两边的 JavaScript 均为 **350477 字节**，
SHA-256 为
`4ce08863b5a109973b3753c80f3547e594b70eff78d941404b0fdd03794850b2`。
最终构建与激活产物：

```text
/nix/store/k32brf86acwjni7228h528cj5d88rsvi-krohnkite-effect-1.0.0
/nix/store/pbq998akb7bqj42xh1vqnmfrh4d3b6g6-krohnkite-qt-runtime
/nix/store/sacpcjp2jdfsl2rahvr3r7nk914akkbr-nixos-system-lvlv-vm-26.11.20260928.7a0f122
```

包 derivation 的 store 哈希为 `vvwa3aaw2alpmvs1myfpfdww1na6fdg2`，VM system
derivation 的 store 哈希为 `id9znhz1cr833rsfwjw9frdkzacfi7rm`。
实体机最终只求值，derivation 为
`/nix/store/nzbp07np40fj086lvdqnmabg8z202h2q-nixos-system-lvlv-26.11.20260928.7a0f122.drv`，
没有构建或部署。
真正 Qt 6.11.2 安装包检查输出
`KROHNKITE_QT_PARTIAL_MAXIMIZE_OK`、`KROHNKITE_QT_INTERNAL_WINDOWS_OK`、
`KROHNKITE_QT_SYNC_BUDGET_OK` 与 `KROHNKITE_QT_SMOKE_OK`，包含两种单轴
最大化还原、内部窗口排除、显式 GC 和 Scope 清理。

最终系统按受保护的流程完成 `dry-activate`、`test`、system profile、`boot` 与
干净单一 Plasma 登录，开始时间为 `2026-10-04T04:54:39-06:00`；KWin wrapper PID
**25422**、实际 compositor PID **25426**、
Plasma Shell PID **25506** 正常运行。最终 live 验收记录为
`/root/krohnkite-effect-live-results-1791111330-25969/result.json`，本地证据在任务
workspace 的 `artifacts/krohnkite-final-live-canary.log`。
两个 kitty 窗口所在 PlacementArea 为 `(0,32,1536,832)`，实际几何如下：

| 阶段 | 窗口 1 `(x,y,width,height)` | 窗口 2 `(x,y,width,height)` | 两窗 maximizeMode |
| --- | --- | --- | --- |
| 默认 Tile，间距 8 | `(8,40,756,816.4)` | `(772,40,756,816.4)` | 0 |
| D-Bus 快捷键切换 Monocle | `(8,40,1520,816.4)` | `(8,40,1520,816.4)` | 3 |
| D-Bus 快捷键返回 Tile | `(8,40,756,816.4)` | `(772,40,756,816.4)` | 0 |
| `kwinrc` + `reconfigure`，间距 16 | `(16,48,744,800.4)` | `(776,48,744,800.4)` | 0 |

验收没有强制初始 Tile，实际调用 KrohnkiteMonocleLayout 1 次、KrohnkiteTileLayout
2 次，并核对几何变化。两窗从 Monocle 返回 Tile 后恢复完整高度，自身通知没有
占据第三个 tile。`artifacts/krohnkite-final-live-kwin.log` 记录了真实
`KROHNKITE_INTERNAL_WINDOW_TYPES [KWin::InternalWindow(0x...)]`。
KWin wrapper 与实际 compositor PID 在验收前后相同，
`NRestarts=0`、`cleanupErrors=[]`；基线、最终及新增失败系统单元均为空。
**最终 sacpcjp2... 系统尚未实际冷启动**；`boot` 成功表示启动配置更新，不能用
旧系统的冷启动记录代替。实体机仍只求值，没有部署。

首次激活尝试停止用户 manager 时没有等它完全结束，引起事务冲突，已自动回滚。
随后显式重启登录后，观察到用户 manager 缺少 `DISPLAY` / `WAYLAND_DISPLAY`，
但 Qt/KWin 已发布显示 socket，桌面辅助程序启动失败。
官方 Plasma 启动清理会还原或删除 manager 中的会话环境变量；完整停止
`display-manager` 和 `user@1000` 后，仅启动一次新登录，恢复了正常环境。
这些结果与登录启动和清理发生重叠一致，但没有追踪证明完整时序，
不能据此确定唯一根因，也不能把这个过程描述成整个 boot 无 coredump。

初次干净登录开始于 **2026-10-04 01:08:16 MDT**：KWin wrapper PID **31244**、
Qt/KWin PID **31249**、Plasma Shell PID **31339**。已观察到
`Effect 4 runtime started`、正确的源码包脚本链接、空的用户失败单元列表及四个
active 的桌面辅助服务。这是旧包的启动与健康记录，不能计为最终包行为通过。
早期只读快照因 Qt 文件缓存而失败，随后改为在加载前预生成全部独有探针文件；
后续又有诊断探针读取已销毁 InternalWindow 的 `minSize`，导致原生 KWin SIGSEGV。
探针现先过滤自有 canary 窗口再读取元数据，并隔离文件缓存；最终记录同时比对
实际 compositor PID，避免只核对仍存活的 wrapper。这个诊断事故保留为历史，
不能描述成整个 boot 无 coredump，也不改变最终独立验收的通过结果。
后续恢复到单一健康登录，KWin 与 Plasma 的进程记录为 **40870 / 40964**，
当时仍使用已激活的上一版系统。后续独立压力测试失败不等于该会话已被替换，
也不改变其他桌面应用既有验收结论。

随后原 QEMU 进程意外退出，SSH 与 QMP 端口均拒绝连接；退出原因未知，
没有据此将它归因于隔离 Qt 测试。原日志已保存在任务 workspace 的
`artifacts/krohnkite-unexpected-vm-exit/`。使用同一磁盘重新冷启动后，当时的
基线检查记录 KWin wrapper PID **884**、Plasma Shell PID **998**，为已激活的
`81qy1459...` 系统。这次恢复冷启动不证明尚未激活的 j5kn1a1h... 系统可用。
生成器转换的实验与最终正式包随后均通过完整原生 Qt 压力用例，最终 Nix 包与
生产会话结果记录在上面；历史 hfga 包的压力失败记录保留。

实体机仍只做配置求值，没有部署；既有 WHPX 原地重启、关机和门户交互限制
保持原验收记录的结论。

## Krohnkite 稳定包模块（2026-10-01，历史）

`lvlv.os` 与 `lvlv-vm` 共用独立 Home Manager 模块及 profile，普通用户启用
`programs.krohnkite`。使用现有锁定 nixpkgs 的稳定包 **0.9.9.2**，源码来自
`anametologin/Krohnkite` 的 Codeberg 仓库；没有增加或更新 flake input。
配置与快捷键说明见 [TILING.md](TILING.md)。

验证通过：

- Alejandra、未声明 input 检查、全仓 Statix / Deadnix **48 / 0**。
- 默认关闭、profile 启用、显式关闭、独立设置与快捷键覆盖、两台主机共享配置。
- 默认关闭时 Home Manager activation derivation 与未注册模块时完全相同；
  额外比较 `k99-lite` 的完整系统 derivation，前后相同。
- 两台主机完整求值、VM 构建退出码 **0**，`dry-activate`、`test`、`boot`
  及 Home Manager 激活通过。构建包含并发任务更新的 Firefox 系统装饰配置。

最终实体机 derivation：
`/nix/store/4d1hmnqkdmrqfqx5b2qclma4dzwmc0n4-nixos-system-lvlv-26.11.20260928.7a0f122.drv`。
VM derivation：
`/nix/store/swx5ldnrn5xwy89x467807v7svikirfm-nixos-system-lvlv-vm-26.11.20260928.7a0f122.drv`。
VM 系统输出：
`/nix/store/bkni3f7xm8cwjh9dzid4m2d8lyz5lqf7-nixos-system-lvlv-vm-26.11.20260928.7a0f122`。

新的 QEMU / WHPX / Native OpenGL 进程冷启动后，KWin 的 `isScriptLoaded("krohnkite")`
返回 true，用户脚本路径指向锁定的 Nix store 包，配置中的启用值为 true、间距为 8。
实际打开两个临时 kitty 窗口，通过只读 KWin 探针记录 frame geometry：
左窗口 x=8、宽 756；右窗口 x=772、宽 756，窗口间距 **8 像素**，均位于 y=40。
KWin 始终 `ActiveState=active`、`NRestarts=0`，系统无失败服务。
临时窗口和探针已关闭、删除；没有重启或反复切换 Krohnkite 实例。

初次同时求值多份 Home Manager 配置时，6 GiB VM 中的并发构建导致内存不足，
内核终止了该次 Nix 求值。改为分项求值及临时 4 GiB swap 后通过；swap 文件
已移除，未写入系统配置。最终冷启动检查使用 8 GiB RAM，不改变常规 runner 默认值。
旧系统保留在 `krohnkite-before` GC root。证据在任务 workspace 的
`artifacts/krohnkite-*` 与 VM 的 `/root/krohnkite-results/`。
实体机仅完成求值，未部署；原地重启限制仍以既有记录为准。

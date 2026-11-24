# lvlv.os

这台 Windows 电脑对应的新 NixOS 主机，硬件清单见 [HARDWARE.md](HARDWARE.md)。
`nixosConfigurations."lvlv.os"` 使用 `hostName = "lvlv"`、`domain = "os"`。
Clan 机器 ID 为 `lvlv`（Clan CLI 不接受带点的名称），`lvlv.os` 是构建目标的别名。
`lvlv-vm` 与实机共用桌面、网络、字体和输入法，仅替换硬件、磁盘、登录及渲染设置。

## 桌面范围

当前锁定 nixos-unstable 的 Plasma **6.7.5**（[KDE 发布说明](https://kde.org/announcements/plasma/6/6.7.5/)），
保留 Dolphin 和系统设置，终端使用 kitty、截图使用 Flameshot。
关闭默认 PIM/Akonadi 和 Qt 5 集成，排除 Konsole、Ark、Spectacle、Discover、Elisa、
Gwenview、Okular、Kate、帮助中心、远程桌面、二维码应用等可选应用。
`excludePackages` 控制用户安装的可选应用，不能保证它们不会作为依赖进入闭包。
保留 Plasma 的网络、音量、通知、锁屏、门户等桌面功能；默认 Wayland + SDDM。
没有引入现有 `base/misc/gui` 大套件，避免附带打印驱动、Samba、Android、游戏等。
中英文 locale、中文字体和 Fcitx5 中文输入单独配置。

应用由 [applications.nix](applications.nix) 和 [terminal-tools.nix](terminal-tools.nix)
显式选择，完整清单、默认应用和终端集成见 [APPLICATIONS.md](APPLICATIONS.md)。
实机与 VM 使用相同应用清单；应用安装验证与基础桌面验证分别记录。

MacTahoe 外观由 **Home Manager + plasma-manager** 管理，包含主题资源、顶部
全局菜单栏、底部 Dock、窗口装饰、图标与光标。配置入口和渲染限制见 [THEME.md](THEME.md)。

Krohnkite 动态平铺由独立 Home Manager 模块管理，两台主机共用默认配置。
启用开关、间距、窗口过滤和快捷键见 [TILING.md](TILING.md)。

## 构建和 VM

Linux/Nix 环境中：

```sh
nix eval --accept-flake-config --raw '.#nixosConfigurations."lvlv.os".config.system.build.toplevel.drvPath'
nix build --accept-flake-config '.#nixosConfigurations.lvlv-vm.config.system.build.toplevel'
```

Windows 使用 [QEMU runner](../../../scripts/vm/windows/README.md)：

```powershell
./scripts/vm/windows/run.ps1 run -VmName lvlv-vm -Graphics Native -MemoryMiB 6144 -Cpus 4
```

默认独立磁盘、UEFI vars、SSH `127.0.0.1:2224`，上述 Native 模式直接打开 SDL 窗口。
按 `Ctrl+Alt+G` 捕获或释放输入。`-Graphics Vnc` 才监听 `127.0.0.1:5912`。
此宿主的 GL 来宾原地重启仍有卡死问题；当前通过的是重新启动 QEMU 进程的冷启动。
正常 runner 要求 WHPX，组件不可用时会报错。VM 专用软件渲染恢复入口、自动登录和放宽的
启动动画超时不会进入实体机配置。VM 使用仓库现有初始用户 `i.want.to.believe`，初始化密码 `nixos`；
SSH 仅通过本机回环转发访问。具体验证结果见 [VALIDATION.md](VALIDATION.md)。

WHPX 未开启时，可以明确选择较慢的 TCG（不修改 Windows 功能）：

```powershell
./scripts/vm/windows/run.ps1 run -VmName lvlv-vm -Graphics Vnc -SoftwareEmulation -MemoryMiB 2048 -Cpus 2
```

## 实机安装前

本任务只验证虚拟机。Windows 扫描无法生成 NixOS 的 UUID、挂载布局或实际驱动状态。
`default.nix` 中 `lvlv-root` / `lvlv-boot` 是预期标签，当前磁盘没有被创建或格式化。
从 NixOS 安装介质启动后，先确认保留 Windows 或重新分区的方案，再根据实际挂载
执行 `nixos-generate-config --show-hardware-config`，用实际结果更新硬件和文件系统
配置。之后再验证显卡、多显示器、Wi-Fi 7、蓝牙和音频。
不要把 VM 的 `/dev/vda` disko 布局用于实体 NVMe。

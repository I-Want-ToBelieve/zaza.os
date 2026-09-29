# Windows QEMU VM

`nixosConfigurations.zaza-vm-windows` 是 Windows 宿主上的 `x86_64-linux`
NixOS 开发 VM。当前 guest 没有图形会话，主要通过 TTY 与 SSH 访问；CPU 必须走
WHPX，QEMU 不会静默回退到 TCG。启动器默认不创建窗口，只使用 PowerShell
中的串口。`zaza-vm-windows-stellar` 是独立的 Stellar 图形开发 VM，使用
`-VmName zaza-vm-windows-stellar` 选择；它有自己的磁盘、UEFI 变量和 SSH 端口。
当前宿主已验证可启动到 SSH 的图形输出路径是 `-Graphics Vnc`：QEMU 自带 VNC
服务提供画面和输入，guest 不需要安装 VNC 服务。

## 宿主准备

```powershell
scoop install main/qemu
```

在管理员 PowerShell 中启用 Windows Hypervisor Platform，然后重启：

```powershell
.\scripts\vm\windows\enable-whpx.ps1
```

如果重启后 `HypervisorPresent` 仍是 `False`，还要在主板 UEFI/BIOS 中启用
Intel Virtualization Technology（VT-x）。检查状态不需要管理员权限：

```powershell
.\scripts\vm\windows\run.ps1 status
```

## 创建并启动

默认状态目录是 `%LOCALAPPDATA%\zaza-vm-windows`，内存 8192 MiB、4 vCPU、
80 GiB 稀疏 qcow2。各命令互相独立：下载 ISO 和创建磁盘不会因为 WHPX 尚未
启用或尚未重启而失败。QMP 默认关闭。

| `-VmName` | 默认状态目录 | 磁盘文件 | SSH 端口 |
| --- | --- | --- | --- |
| `zaza-vm-windows`（默认） | `%LOCALAPPDATA%\zaza-vm-windows` | `zaza-vm-windows.qcow2` | 2222 |
| `zaza-vm-windows-stellar` | `%LOCALAPPDATA%\zaza-vm-windows-stellar` | `zaza-vm-windows-stellar.qcow2` | 2223 |

所有命令都接受 `-VmName`。`-State` 和 `-SshPort` 可覆盖默认值；即使显式共用
`-State`，两个 VM 仍使用不同的 qcow2 和 UEFI vars 文件。不要把已有 TTY 磁盘
重命名成 Stellar 磁盘，Stellar 应从独立磁盘安装。

```powershell
.\scripts\vm\windows\run.ps1 fetch-iso
.\scripts\vm\windows\run.ps1 create-disk
.\scripts\vm\windows\run.ps1 install
```

已经有 ISO 时不用复制它，可直接指定路径；启动前仍会检查固定的长度和 SHA-256：

```powershell
.\scripts\vm\windows\run.ps1 install -IsoPath 'D:\path\to\nixos-minimal-x86_64-linux.iso'
```

默认的 headless 模式不会打开 SDL 窗口。ISO 的 UEFI GRUB 会把菜单画到虚拟显卡，
但不读取 ttyS0 键盘；按 `Ctrl-a c` 进入 QEMU monitor，用 `sendkey` 选择
**Serial console (ttyS0, 115200n8)**，再按 `Ctrl-a c` 返回串口。随后安装器 TTY
会出现在 PowerShell 中。`Ctrl-a x` 退出。安装器不会自动分区，也不会覆盖已经
存在的 qcow2 或 UEFI vars。

如果首次安装时希望直接看到并操作引导菜单，使用 VNC 显示：

```powershell
.\scripts\vm\windows\run.ps1 install -Graphics Vnc
```

显示模式如下；CPU 在所有模式下都使用 WHPX：

| `-Graphics` | 虚拟显卡 | QEMU 显示 | 用途 |
| --- | --- | --- | --- |
| `Headless`（默认） | `virtio-vga` | `none` | 串口 TTY / SSH |
| `Vnc` | `virtio-vga` | `none` + QEMU VNC | 当前宿主已验证的启动路径 |
| `Software` | `virtio-vga` | `sdl,gl=off` | 实验性 SDL 软件显示，当前宿主曾冻结 |
| `Native` | `virtio-vga-gl` | `sdl,gl=on` | 实验性宿主 OpenGL / VirGL |
| `Angle` | `virtio-vga-gl` | `sdl,gl=es` | 实验性 SDL/ANGLE 路径 |

VNC 仅监听 `127.0.0.1`：TTY VM 默认端口 `5910`，Stellar 默认端口 `5911`。
用 VNC 客户端连接该 TCP 端口，或使用宿主上的 noVNC 桥接；启动器不会自动打开
客户端窗口。可通过 `-VncPort` 指定 `5900`–`65535` 的 TCP 端口，启动器自动转换为
QEMU 的 display 编号。例如 `-VncPort 5911` 生成 `-vnc 127.0.0.1:11`。
启用 VNC 时，其端口必须与 SSH 和 QMP 不同；其它显示模式不监听 VNC 端口。

Stellar guest 使用 KWin QPainter 软件合成和 Mesa 软件渲染；`Vnc` 和 `Software`
均不提供宿主 GPU 的 3D 加速。当前宿主实测 SDL `gl=off` 也会令整个 guest 冻结，
包括 QMP 失去响应；相同配置改用 QEMU VNC 后可启动 SSH。因此首次启动使用 `Vnc`，
桌面会话本身仍需单独验证。需要研究 SDL/GL 时，可显式选择：

```powershell
.\scripts\vm\windows\run.ps1 install -Graphics Software
.\scripts\vm\windows\run.ps1 install -Graphics Native
.\scripts\vm\windows\run.ps1 install -Graphics Angle
```

`Native` 和 `Angle` 的可用性取决于宿主驱动和 QEMU 构建，曾出现冻结，不能作为
Stellar 基线。`-Graphics` 只决定 QEMU 如何显示；minimal ISO 及 TTY guest 不会
因为启用图形输出而拥有桌面。

## 独立 Stellar VM

先创建新磁盘，复用已有且经校验的 ISO；下面的 ISO 名称可从 `nixos-image.json`
读取，也可直接传递自己的完整路径：

```powershell
$isoName = (Get-Content .\scripts\vm\windows\nixos-image.json -Raw | ConvertFrom-Json).fileName
$isoPath = Join-Path $env:LOCALAPPDATA "zaza-vm-windows\$isoName"
.\scripts\vm\windows\run.ps1 create-disk -VmName zaza-vm-windows-stellar
.\scripts\vm\windows\run.ps1 install -VmName zaza-vm-windows-stellar -Graphics Vnc -IsoPath $isoPath
```

安装步骤与下文相同，但 SSH 使用端口 `2223`，flake 目标使用
`/path/to/zaza.os#zaza-vm-windows-stellar`。安装后：

```powershell
.\scripts\vm\windows\run.ps1 run -VmName zaza-vm-windows-stellar -Graphics Vnc
ssh -p 2223 i.want.to.believe@127.0.0.1
```

## 检查启动计划

`run` 和 `install` 支持 `-DryRun`，返回可供脚本检查的对象。该模式只读取 QEMU
安装路径和 ISO 元数据，不启动 VM、不创建状态目录/磁盘/UEFI vars，也不改变
SDL 环境变量。它跳过 WHPX、磁盘存在性和 ISO 内容校验，因此只验证启动参数，
不能代替真实启动检查。仍需要通过 Scoop 安装 QEMU。

```powershell
.\scripts\vm\windows\run.ps1 run -VmName zaza-vm-windows-stellar -Graphics Vnc -DryRun | ConvertTo-Json -Depth 4
.\scripts\vm\windows\run.tests.ps1
```

返回对象的 `VncEndpoint` 为 VNC 的实际 TCP 端点，非 VNC 模式为 `null`。测试覆盖
默认 TTY、独立 Stellar 状态、五种显示模式、SSH/QMP/VNC 冲突、VNC 端口转换和
包含空格或逗号的路径，并验证 dry-run 不创建状态或更改 SDL 环境。
`run.tests.ps1` 自行创建并清理临时 QEMU/固件占位文件，以测试作用域内的 Scoop
函数提供安装路径；无需安装 QEMU、Scoop 或启用 WHPX，不执行占位程序，也不修改
用户安装或环境变量。因此可以直接在 Windows CI 中运行。

## 用 flake 安装

ISO 中先为 root 设置临时口令：

```console
sudo passwd root
```

另开一个 Windows 终端，通过只绑定到回环地址的转发连接：

```powershell
ssh -p 2222 root@127.0.0.1
```

把包含 `zaza-vm-windows` 的提交放到 guest 可访问的位置后，在 guest 内运行：

```bash
sudo nix --extra-experimental-features 'nix-command flakes' \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake '/path/to/zaza.os#zaza-vm-windows' \
  --disk main /dev/vda
```

`main` 对应 `hosts/virtual/zaza-vm-windows/disk-config.nix`，布局为 GPT、512 MiB
ESP 和 ext4 根分区。装完退出 QEMU，之后从磁盘启动：

```powershell
.\scripts\vm\windows\run.ps1 run
```

该命令默认直接在当前 PowerShell 中打开串口 TTY，不创建图形窗口。

日常 SSH：

```powershell
ssh -p 2222 i.want.to.believe@127.0.0.1
```

仓库当前仍给 root 和 `i.want.to.believe` 设置初始化口令 `nixos`，且允许 root
密码登录。端口转发只监听 `127.0.0.1`，但安装完成后仍应尽快更换口令或切换到
clan vars 管理的密码。

资源和 SSH 端口可以逐次覆盖，例如：

```powershell
.\scripts\vm\windows\run.ps1 run -Cpus 6 -MemoryMiB 12288 -SshPort 2223
```

需要让本机自动化直接控制 QEMU 时，可以显式加 `-QmpPort 4444`。QMP 没有认证，
拥有电源、内存和设备控制权限；即使监听地址是 `127.0.0.1`，同机其它用户或进程
也可能连接，所以不要默认打开。

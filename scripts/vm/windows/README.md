# zaza-vm-windows

`nixosConfigurations.zaza-vm-windows` 是 Windows 宿主上的 `x86_64-linux`
NixOS 开发 VM。当前 guest 没有图形会话，主要通过 TTY 与 SSH 访问；CPU 必须走
WHPX，QEMU 不会静默回退到 TCG。启动器默认不创建窗口，只使用 PowerShell
中的串口；显式选择 `Native` 或 `Angle` 时才使用 SDL 与 `virtio-vga-gl`。

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

如果首次安装时希望直接看到并操作引导菜单，可显式打开原生 SDL/OpenGL：

```powershell
.\scripts\vm\windows\run.ps1 install -Graphics Native
```

如果宿主原生 OpenGL 后端有问题，可显式改用 SDL/ANGLE 的 D3D11 路径：

```powershell
.\scripts\vm\windows\run.ps1 install -Graphics Angle
```

`Native` 和 `Angle` 都使用 `virtio-vga-gl`。默认 headless 模式改用非 GL 的
`virtio-vga` 并传递 `-display none`，因此不会初始化 SDL/OpenGL。TTY 阶段 guest
没有启用 Mesa 用户态图形栈，
所以现在的用途是可靠显示引导/控制台，并为之后的桌面配置保留 VirGL 设备。

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

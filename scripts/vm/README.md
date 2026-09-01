# zaza-vm —— macOS 上的 NixOS 桌面开发机

`nixosConfigurations.zaza-vm`，aarch64-linux，跑在 QEMU + Hypervisor.framework 上。
桌面选型和 shell 开发在这里做。

## 为什么长这样

| 决定                                       | 理由                                                                                                                                                                                                                                                                                                                             |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| aarch64 而非 x86_64                        | 宿主是 Apple Silicon，只有同架构才能用 HVF 做 CPU 加速。x86_64 要走 TCG 纯模拟，慢到没法开发桌面。**代价：这台机器验证不了教室机的真实闭包。**                                                                                                                                                                                   |
| 桌面是 KineticWE（KWin 分支）而非 Hyprland | 目标是精确模仿 macOS，而 macOS 最标志性的是全局菜单栏。承载它的 `kde-appmenu` Wayland 协议**只有 KWin 系实现**。详见 CLAUDE.md 的「The desktop: KineticWE + Noctalia (Stellar Shell)」。                                                                                                                                         |
| 只给 2D 显卡，但够用                       | Homebrew qemu 9.2.3 与 nixpkgs qemu 11.1.0 **都没有** `virtio-gpu-gl`，也没链 virglrenderer（已逐一核实），所以 `virtio-gpu-pci` 只有 dumb buffer。但 KWin 保留了软件合成后端（`src/backends/drm/drm_qpainter_backend.cpp`，`KWIN_COMPOSE=Q` 选它）—— 正是 Hyprland 连同 pixman 一起砍掉的那个。于是 KWin 能直接画在这块显卡上。 |
| 画面走 **QEMU 侧**的 `-vnc`                | guest 里零 VNC 软件。键鼠由 virtio-input 注入（用 `virtio-tablet` 而非 `virtio-mouse` —— VNC 送的是绝对坐标）。**合成器起不来时照样看得见引导过程**，这在造桌面的阶段比清晰度重要。                                                                                                                                              |
| noVNC 桥跑在**宿主**                       | 因为 VNC 服务端现在在 QEMU 这侧。`./scripts/vm/run.sh novnc`。                                                                                                                                                                                                                                                                   |
| VNC 用 display `:10`（5910）而非 `:0`      | macOS 自己在 `*.5900` 上有一个 root 拥有的通配监听（屏幕共享），`:0` 会以 `Failed to find an available port: Address already in use` 失败。注意 `lsof` 不带 sudo 归不到那个进程，`netstat -an -p tcp` 才看得见。                                                                                                                 |

宿主将来换成能做 3D 的 runner（UTM 自带打了 virglrenderer/ANGLE 的 QEMU）时，
**guest 配置一行都不用改** —— 这是把 guest 声明进 flake、runner 留在脚本里的意义。

## 资源

6 GB RAM / 30 GB 磁盘 / 4 vCPU。宿主一共 16 GB / 62 GB 可用，这是保守档。
可用环境变量覆盖：`ZAZA_VM_MEM`、`ZAZA_VM_DISK`、`ZAZA_VM_CPUS`。
状态目录 `~/.local/share/zaza-vm`（`ZAZA_VM_STATE` 可改）。

## 装机

```bash
./scripts/vm/run.sh fetch-iso      # NixOS aarch64 minimal ISO，约 1 GB
./scripts/vm/run.sh create-disk    # 30 GB 稀疏 qcow2
./scripts/vm/run.sh install        # 从 ISO 引导
```

`install` 之后你会拿到 ISO 的串口终端。**唯一需要你手工做的一步**是设一个临时
口令 —— 安装 ISO 上 sshd 默认开着、`PermitRootLogin = yes`，但 root 和 nixos
的口令都是**空**的，而 sshd 拒绝空口令登录（见 nixpkgs 的
`nixos/modules/profiles/installation-device.nix`）：

```bash
sudo passwd root   # getty 自动登录为 nixos，故用 sudo
```

然后**另开一个终端**，从 Mac 这侧：

```bash
ssh -p 2222 root@127.0.0.1
```

进去之后，在 **guest 内部**装机：

```bash
sudo nix --extra-experimental-features 'nix-command flakes' \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake 'github:I-Want-ToBelieve/zaza.os/refactor/p1-baseline#zaza-vm' \
  --disk main /dev/vda
```

`main` 是 `hosts/virtual/zaza-vm/disk-config.nix` 里 `disko.devices.disk.main`
的名字；`--disk` 会覆盖掉配置里的 `device` 默认值。

装完关掉 QEMU（串口里 `Ctrl-a` 然后 `x`），改用 `./scripts/vm/run.sh run`。

### 为什么是 disko-install 而不是 nixos-anywhere

`nixos-anywhere` 是为**够不着的远程机器**设计的：它要处理 kexec 进安装环境、
SSH 密钥编排、把闭包推过去。这里一样都用不上 —— 这是一台本地 VM，串口就在
手边，guest 自己能上网。

而且 macOS 造不出 Linux derivation，走 nixos-anywhere 就必须加
`--build-on-remote`，绕一圈之后**实际构建仍然发生在 guest 里** —— 那还不如
一开始就在 guest 里装。`disko-install` 把 disko 分区和 `nixos-install` 合成
一步，没有 SSH 编排、没有宿主侧工具、也不需要额外拉一个 GitHub 项目
（disko 本来就是 clan-core 带进来的 input）。

**`clan machines install` 不是替代品** —— 已核实它内部就是 exec
`nixos-anywhere --flake <flake>#<machine>`（clan-core 的
`clan_lib/machines/install.py:139`），只是额外做了 vars 下发和 kexec 密钥。
等 `clan vars generate` 真正跑起来之后它才有独立价值，现在 `flake/vars.nix`
还是惰性的。

其余考虑过但不适用的：`nixos-generators` / `nixos-rebuild build-image` 要在
Linux 上构建镜像，这台 Mac 做不到；`nixos-rebuild --target-host` 要求目标机
已经装好 NixOS。

## 日常

```
SSH    ssh -p 2222 root@127.0.0.1
VNC    127.0.0.1:5910                 （任意 VNC 客户端）
noVNC  ./scripts/vm/run.sh novnc  →  http://127.0.0.1:6080/vnc.html
```

桌面是 **KineticWE + Noctalia**。架构和选它的理由见 CLAUDE.md 的
「The desktop: KineticWE + Noctalia (Stellar Shell)」一节。greetd 配了自动登录，
改完配置 `nixos-rebuild switch` 之后 `systemctl restart greetd` 即可重启会话。

改配置后在 guest 里：

```bash
nixos-rebuild switch --flake /path/to/zaza.os#zaza-vm
```

仓库可以用 `rsync -e 'ssh -p 2222'` 推进去，或者在 guest 里 git clone。

装好之后 guest 还能当 Mac 的 **aarch64-linux 远程 builder** —— 这样
`nix build --system aarch64-linux` 在 Mac 上也能用。

### 首次构建会编译 KWin

KineticWE 没有二进制缓存（flake 里无 `nixConfig`），而它是一个 624 个 `.cpp`
的 KWin 分支。6 GB 内存在链接 Qt 时偏紧，建议首次临时加大：

```bash
ZAZA_VM_MEM=10240 ZAZA_VM_CPUS=6 ./scripts/vm/run.sh run
```

仍然 OOM 就在 guest 里退一步：
`nixos-rebuild switch --flake ... --cores 2 --max-jobs 1`。

## 尚未验证的部分

以下只过了求值，**没有实机跑过**，第一次装机时要逐条确认：

- KineticWE 的 KWin 分支能否在 aarch64 上构建完（无缓存，6 GB 偏紧）
- KWin 的 QPainter 后端（`KWIN_COMPOSE=Q`）能否在 `virtio-gpu-pci` 的
  dumb buffer 上起来
- greetd 自动登录进 `start-kineticwe` 后 XDG_RUNTIME_DIR / dbus 是否正确建立
- QEMU 的 `-vnc` 能否拿到 virtio-gpu 的画面；virtio-tablet 的指针位置是否对得上
- Noctalia 是否随 session 一起起来

排查顺序：`journalctl -u greetd`（合成器起没起）→ guest 内 `grim` 截图
（会话有没有画面，与 VNC 那条路互为佐证）→ QEMU 串口（连引导都没到的话，
只有这里看得见）。

# zaza-vm —— macOS 上的 NixOS 桌面开发机

`nixosConfigurations.zaza-vm`，aarch64-linux，跑在 QEMU + Hypervisor.framework 上。
桌面选型和 shell 开发在这里做。

## 为什么长这样

| 决定                                | 理由                                                                                                                                                                                                   |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| aarch64 而非 x86_64                 | 宿主是 Apple Silicon，只有同架构才能用 HVF 做 CPU 加速。x86_64 要走 TCG 纯模拟，慢到没法开发桌面。**代价：这台机器验证不了教室机的真实闭包。**                                                         |
| 不给 VM 配显卡                      | Homebrew qemu 9.2.3 与 nixpkgs qemu 11.1.0 **都没有** `virtio-gpu-gl`，也没链 virglrenderer（已逐一核实）。而 `virtio-gpu-pci` 只有 dumb buffer，Hyprland 是纯 GLES（已砍掉 pixman），DRM 后端起不来。 |
| 画面走 guest 内的 headless + wayvnc | 绕开 DRM：wlroots 的 headless 后端建纯内存虚拟输出，GLES 交给 llvmpipe 软件渲染，wayvnc 把 buffer 推出去。**这条链路不碰显卡，宿主有没有 3D 转发都不影响。**                                           |
| noVNC 那一层                        | 让桌面能被浏览器直接打开，不必在 Mac 上装 VNC 客户端。                                                                                                                                                 |

宿主将来换成能做 3D 的 runner（UTM 自带打了 virglrenderer/ANGLE 的 QEMU），
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
noVNC  http://127.0.0.1:6080/vnc.html
```

改配置后在 guest 里：

```bash
nixos-rebuild switch --flake /path/to/zaza.os#zaza-vm
```

仓库可以用 `rsync -e 'ssh -p 2222'` 推进去，或者在 guest 里 git clone。

装好之后 guest 还能当 Mac 的 **aarch64-linux 远程 builder** —— 这样
`nix build --system aarch64-linux` 在 Mac 上也能用。

## 尚未验证的部分

以下只过了求值，**没有实机跑过**，第一次装机时要逐条确认：

- Hyprland 的 headless 后端能否在 llvmpipe 上真的起来（`WLR_BACKENDS=headless`）
- wayvnc 能否附着到 `HEADLESS-1` 输出
- greetd 的 autologin 会话里 `XDG_RUNTIME_DIR` / dbus 是否正确建立
- noVNC 经 QEMU hostfwd 的端口转发是否通

出问题的排查顺序：`journalctl -u greetd`（合成器起没起）→
`journalctl -u novnc`（代理起没起）→ guest 内 `grim` 截图（会话有没有画面，
可与 VNC 那条路互为佐证）。

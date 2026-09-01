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

`install` 之后你会拿到 ISO 的串口终端。在里面：

```bash
sudo -i
passwd            # 给 root 设一个临时口令，装完就没用了
ip -4 addr show   # 应当是 10.0.2.15/24（QEMU 用户态 NAT）
```

sshd 在安装 ISO 上默认是开的，QEMU 已把宿主 `127.0.0.1:2222` 转发到 guest 的 22。
**另开一个终端**，从仓库根目录：

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake '.#zaza-vm' \
  --option pure-eval false \
  --build-on-remote --print-build-logs \
  --ssh-port 2222 root@127.0.0.1
```

`--build-on-remote` 是必须的：macOS 造不出 Linux derivation。绝大部分闭包会从
cache.nixos.org 直接替换（aarch64-linux 是 Hydra 全量构建的平台），真正需要在
guest 里构建的只有 `nixos-system-zaza-vm` 这类很小的东西。

装完关掉 QEMU（串口里 `Ctrl-a` 然后 `x`），改用：

```bash
./scripts/vm/run.sh run
```

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

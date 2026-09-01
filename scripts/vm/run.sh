#!/usr/bin/env bash
# zaza-vm 启动器 —— macOS / Apple Silicon 上的 aarch64 NixOS 开发机。
#
# 为什么是 QEMU + HVF 而不是别的：
#   - CPU 加速走 Hypervisor.framework（`accel=hvf`），已实测可用。
#   - 图形加速这台机器上**拿不到**：Homebrew 的 qemu 9.2.3 和 nixpkgs 的
#     qemu 11.1.0 都没有 virtio-gpu-gl，也没链 virglrenderer（已逐一核实）。
#     给的是纯 2D 的 virtio-gpu-pci（只有 dumb buffer）。桌面是 KineticWE
#     （KWin 分支），而 KWin 保留了软件合成后端，能直接画在上面 —— 那正是
#     Hyprland 砍掉、因而跑不了这块显卡的东西。
#   - 画面走 QEMU 自己的 -vnc，guest 里零 VNC 软件；键鼠由 virtio-input
#     注入。附带好处：合成器起不来时照样看得见引导过程。
#
# 用法：
#   run.sh fetch-iso     下载 NixOS aarch64 minimal ISO
#   run.sh create-disk   创建 qcow2 磁盘
#   run.sh install       从 ISO 引导（装机用，见 README.md）
#   run.sh run           从磁盘引导（日常）
#   run.sh novnc         在宿主起 noVNC 桥，用浏览器看 VM 画面
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
STATE="${ZAZA_VM_STATE:-$HOME/.local/share/zaza-vm}"
DISK="$STATE/zaza-vm.qcow2"
VARS="$STATE/edk2-vars.fd"
ISO="$STATE/nixos-minimal-aarch64.iso"

# 与 AskUserQuestion 里定的保守预算一致：宿主一共 16 GB / 62 GB 可用。
MEM_MB="${ZAZA_VM_MEM:-6144}" # 6 GB
DISK_GB="${ZAZA_VM_DISK:-30}" # 30 GB（qcow2 稀疏，实际占用按写入量增长）
CPUS="${ZAZA_VM_CPUS:-4}"     # 宿主 10 核，留 6 个给 macOS

FW_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
FW_VARS=/opt/homebrew/share/qemu/edk2-arm-vars.fd

SSH_PORT="${ZAZA_VM_SSH_PORT:-2222}"
WEB_PORT="${ZAZA_VM_WEB_PORT:-6080}" # noVNC 的 http（跑在宿主上）
# QEMU 的 VNC → 127.0.0.1:(5900+N)。
# 默认取 10 而不是 0：macOS 自己在 *.5900 上有一个 root 拥有的通配监听
# （屏幕共享 / ARD），display :0 会直接以
# "Failed to find an available port: Address already in use" 失败。
# 注意 lsof 不带 sudo 归不到那个进程，netstat -an -p tcp 才看得见。
VNC_DISPLAY="${ZAZA_VM_VNC_DISPLAY:-10}"
VNC_PORT=$((5900 + VNC_DISPLAY))

die() {
  echo "错误: $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null || die "找不到 $1"; }

mkdir -p "$STATE"

qemu_common() {
  # `-cpu host` 只在 hvf 下有效；highmem 让 6 GB 以上内存能映射。
  #
  # virtio-gpu-pci 是纯 2D（dumb buffer，无 virgl）。KWin 的
  # drm_qpainter_backend 能直接用它，配 KWIN_COMPOSE=Q。
  #
  # virtio-tablet 而不是 virtio-mouse：VNC 送的是**绝对**坐标，相对坐标的
  # 鼠标会让指针位置对不上。
  #
  # -vnc 本身就是一个 display 后端，所以不再给 -display none。
  printf '%s\n' \
    -machine "virt,accel=hvf,highmem=on" \
    -cpu host \
    -smp "$CPUS" \
    -m "$MEM_MB" \
    -drive "if=pflash,format=raw,readonly=on,file=$FW_CODE" \
    -drive "if=pflash,format=raw,file=$VARS" \
    -device virtio-rng-pci \
    -device virtio-gpu-pci \
    -device virtio-keyboard-pci \
    -device virtio-tablet-pci \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22" \
    -device virtio-net-pci,netdev=net0 \
    -vnc "127.0.0.1:$VNC_DISPLAY" \
    -serial mon:stdio
}

cmd_fetch_iso() {
  need curl
  [ -f "$ISO" ] && {
    echo "已存在：$ISO"
    return
  }
  echo "下载 NixOS aarch64 minimal ISO …"
  curl -fL --progress-bar \
    https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso \
    -o "$ISO.part"
  mv "$ISO.part" "$ISO"
  echo "→ $ISO"
}

cmd_create_disk() {
  need qemu-img
  [ -f "$DISK" ] && die "磁盘已存在：$DISK（要重建请先手工删除）"
  qemu-img create -f qcow2 "$DISK" "${DISK_GB}G"
  echo "→ $DISK (${DISK_GB} GB, 稀疏)"
}

# EFI 变量存储必须是可写副本：只读地用 edk2-arm-vars.fd 会让 systemd-boot
# 装不上引导项。每次 install 重置，run 时保留。
reset_vars() { cp -f "$FW_VARS" "$VARS"; }

cmd_install() {
  need qemu-system-aarch64
  [ -f "$ISO" ] || die "先跑 $0 fetch-iso"
  [ -f "$DISK" ] || die "先跑 $0 create-disk"
  reset_vars
  echo "从 ISO 引导。装机步骤见 scripts/vm/README.md。"
  echo "退出 QEMU：在串口里按 Ctrl-a 然后 x"
  # shellcheck disable=SC2046
  exec qemu-system-aarch64 $(qemu_common) \
    -drive "if=virtio,format=qcow2,file=$DISK" \
    -drive "if=virtio,format=raw,media=cdrom,readonly=on,file=$ISO"
}

cmd_run() {
  need qemu-system-aarch64
  [ -f "$DISK" ] || die "先跑 $0 create-disk"
  [ -f "$VARS" ] || reset_vars
  echo "SSH:   ssh -p $SSH_PORT root@127.0.0.1"
  echo "VNC:   127.0.0.1:$VNC_PORT   （浏览器看画面：另开终端跑 $0 novnc）"
  echo "退出 QEMU：在串口里按 Ctrl-a 然后 x"
  # shellcheck disable=SC2046
  exec qemu-system-aarch64 $(qemu_common) \
    -drive "if=virtio,format=qcow2,file=$DISK"
}

# 画面现在由 QEMU 提供，所以 noVNC 这一层必须跑在**宿主**上，不是 guest 里。
cmd_novnc() {
  need nix
  echo "noVNC → http://127.0.0.1:$WEB_PORT/vnc.html  (后端 127.0.0.1:$VNC_PORT)"
  echo "Ctrl-C 结束"
  exec nix run --impure nixpkgs#python3Packages.websockify -- \
    --web "$(nix build --no-link --print-out-paths nixpkgs#novnc)/share/webapps/novnc" \
    "127.0.0.1:$WEB_PORT" "127.0.0.1:$VNC_PORT"
}

case "${1:-}" in
fetch-iso) cmd_fetch_iso ;;
novnc) cmd_novnc ;;
create-disk) cmd_create_disk ;;
install) cmd_install ;;
run) cmd_run ;;
*)
  sed -n '2,20p' "$0" >&2
  exit 2
  ;;
esac

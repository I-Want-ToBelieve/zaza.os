#!/usr/bin/env bash
# zaza-vm 启动器 —— macOS / Apple Silicon 上的 aarch64 NixOS 开发机。
#
# 为什么是 QEMU + HVF 而不是别的：
#   - CPU 加速走 Hypervisor.framework（`accel=hvf`），已实测可用。
#   - 图形加速这台机器上**拿不到**：Homebrew 的 qemu 9.2.3 和 nixpkgs 的
#     qemu 11.1.0 都没有 virtio-gpu-gl，也没链 virglrenderer（已逐一核实）。
#     所以这里根本不给 VM 配显卡 —— 桌面走 guest 内的 headless 合成器 +
#     wayvnc，见 profiles/nixos/remote-desktop.nix。宿主将来换成 UTM 之类
#     能做 3D 的 runner 时，guest 配置一行都不用改。
#
# 用法：
#   run.sh fetch-iso     下载 NixOS aarch64 minimal ISO
#   run.sh create-disk   创建 qcow2 磁盘
#   run.sh install       从 ISO 引导（装机用，见 README.md）
#   run.sh run           从磁盘引导（日常）
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
WEB_PORT="${ZAZA_VM_WEB_PORT:-6080}"

die() {
  echo "错误: $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null || die "找不到 $1"; }

mkdir -p "$STATE"

qemu_common() {
  # `-cpu host` 只在 hvf 下有效；highmem 让 6 GB 以上内存能映射。
  # 刻意不加任何 -device virtio-gpu*：没有 3D 的显卡对 Hyprland 没用，
  # 反而会让 wlroots 去试 DRM 后端然后失败。画面走 VNC。
  printf '%s\n' \
    -machine "virt,accel=hvf,highmem=on" \
    -cpu host \
    -smp "$CPUS" \
    -m "$MEM_MB" \
    -drive "if=pflash,format=raw,readonly=on,file=$FW_CODE" \
    -drive "if=pflash,format=raw,file=$VARS" \
    -device virtio-rng-pci \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22,hostfwd=tcp:127.0.0.1:$WEB_PORT-:$WEB_PORT" \
    -device virtio-net-pci,netdev=net0 \
    -display none \
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
  echo "noVNC: http://127.0.0.1:$WEB_PORT/vnc.html"
  echo "退出 QEMU：在串口里按 Ctrl-a 然后 x"
  # shellcheck disable=SC2046
  exec qemu-system-aarch64 $(qemu_common) \
    -drive "if=virtio,format=qcow2,file=$DISK"
}

case "${1:-}" in
fetch-iso) cmd_fetch_iso ;;
create-disk) cmd_create_disk ;;
install) cmd_install ;;
run) cmd_run ;;
*)
  sed -n '2,20p' "$0" >&2
  exit 2
  ;;
esac

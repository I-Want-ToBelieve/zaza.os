#!/usr/bin/env bash
# 等价性 harness：证明一次重构没有改变任何主机的求值结果。
#
# 判据是 config.system.build.toplevel.drvPath 相等 —— 比 outPath 更强，且**无需构建**，
# 所以在构不了 x86_64-linux 的 macOS 上也能跑完。
#
# 用法:
#   equiv.sh <base-ref> [<cand-ref>]      # cand 缺省为当前工作树
#   equiv.sh baseline-p1
#   equiv.sh baseline-p1 HEAD --allow k99-lite      # 允许指定主机出现差异
#
# 前提：两侧的 flake.lock 必须一致。lock 不同则 drvPath 必然不同，比较得不出任何结论，
# 所以这里直接拒绝运行而不是给出误导性的红色输出。
set -euo pipefail

BASE="${1:-}"
[ -n "$BASE" ] || {
  echo "用法: $0 <base-ref> [<cand-ref>] [--allow <host>]..." >&2
  exit 2
}
shift
CAND=""
ALLOW=()
while [ $# -gt 0 ]; do
  case "$1" in
  --allow)
    ALLOW+=("$2")
    shift 2
    ;;
  *)
    CAND="$1"
    shift
    ;;
  esac
done

REPO=$(git rev-parse --show-toplevel)
cd "$REPO"

TMP=$(mktemp -d)
WT_BASE="$TMP/base"
cleanup() {
  git worktree remove --force "$WT_BASE" 2>/dev/null || true
  [ -n "${WT_CAND:-}" ] && git worktree remove --force "$WT_CAND" 2>/dev/null
  rm -rf "$TMP"
}
trap cleanup EXIT

echo "==> 检出 base: $BASE"
git worktree add -q --detach "$WT_BASE" "$BASE"

if [ -n "$CAND" ]; then
  echo "==> 检出 cand: $CAND"
  WT_CAND="$TMP/cand"
  git worktree add -q --detach "$WT_CAND" "$CAND"
  CAND_DIR="$WT_CAND"
  CAND_LABEL="$CAND"
else
  # 当前工作树。注意它可能是脏的 —— 那正是重构进行中的常态。
  CAND_DIR="$REPO"
  CAND_LABEL="工作树"
fi

# lock 一致性闸门
if ! diff -q "$WT_BASE/flake.lock" "$CAND_DIR/flake.lock" >/dev/null 2>&1; then
  echo >&2
  echo "拒绝运行：两侧 flake.lock 不同。" >&2
  echo "lock 不同则 drvPath 必然不同，比较得不出结论。" >&2
  exit 3
fi

evaluate() {
  nix eval --impure --accept-flake-config --json "$1#nixosConfigurations" \
    --apply 'c: builtins.mapAttrs (_: v: v.config.system.build.toplevel.drvPath) c' \
    2>/dev/null
}
evaluate_darwin() {
  nix eval --impure --accept-flake-config --raw \
    "$1#darwinConfigurations.k99-lite-darwin.config.system.build.toplevel.drvPath" \
    2>/dev/null || echo "<求值失败>"
}

echo "==> 求值 base（8 台 NixOS + darwin，可能要几分钟）"
evaluate "$WT_BASE" >"$TMP/base.json"
evaluate_darwin "$WT_BASE" >"$TMP/base.darwin"

echo "==> 求值 cand"
evaluate "$CAND_DIR" >"$TMP/cand.json"
evaluate_darwin "$CAND_DIR" >"$TMP/cand.darwin"

echo
ALLOW_CSV=$(
  IFS=,
  echo "${ALLOW[*]:-}"
)
BASE="$BASE" CAND_LABEL="$CAND_LABEL" ALLOW_CSV="$ALLOW_CSV" TMP="$TMP" python3 - <<'PY'
import json, os, sys

tmp = os.environ["TMP"]
allow = {h for h in os.environ.get("ALLOW_CSV", "").split(",") if h}
base = json.load(open(f"{tmp}/base.json"))
cand = json.load(open(f"{tmp}/cand.json"))
base["k99-lite-darwin"] = open(f"{tmp}/base.darwin").read().strip()
cand["k99-lite-darwin"] = open(f"{tmp}/cand.darwin").read().strip()

print(f"{'配置':<26} {'结果'}")
print("-" * 60)
bad = []
for name in sorted(base):
    b, c = base[name], cand.get(name)
    if b == c:
        print(f"{name:<26} 相同")
    elif name in allow:
        print(f"{name:<26} 不同（已在 --allow 列表）")
    else:
        print(f"{name:<26} ** 不同 **")
        bad.append((name, b, c))
for name in sorted(set(cand) - set(base)):
    print(f"{name:<26} ** base 中不存在 **")
    bad.append((name, "<缺失>", cand[name]))

print()
if bad:
    for name, b, c in bad:
        print(f"{name}\n  base: {b}\n  cand: {c}")
    print()
    print("根因定位：")
    for name, b, c in bad:
        if b.startswith("/nix/store") and c.startswith("/nix/store"):
            print(f"  nix run nixpkgs#nix-diff -- {b} {c}")
    sys.exit(1)
print(f"全部一致：{os.environ['BASE']} == {os.environ['CAND_LABEL']}")
PY

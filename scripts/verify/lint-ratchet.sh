#!/usr/bin/env bash
# lint 棘轮：statix 与 deadnix 的发现数只允许下降，不允许上升。
#
# 为什么不是「必须为零」：statix 剩下的全是 W20（重复 key），它只报不修，
# 需要人工把 `a.b = …; a.c = …;` 重构成 `a = { b = …; c = …; };`。那是代码形态
# 偏好而不是缺陷，为它改二十几个文件属于无收益的 churn。棘轮让它不再增长，
# 顺手重构到的自然会降下来。
#
# 用法:
#   lint-ratchet.sh <仓库根> <statix 上限> <deadnix 上限>
set -euo pipefail

ROOT="${1:?需要仓库根路径}"
MAX_STATIX="${2:?需要 statix 上限}"
MAX_DEADNIX="${3:?需要 deadnix 上限}"

# statix 与 deadnix 在「有发现」时都以非零退出，而本脚本开了 pipefail ——
# 所以两处计数都必须显式吞掉退出码，否则脚本会在第一行赋值处静默死掉。
# pkgs/_sources/generated.nix 由 nvfetcher 生成，永不手改，因此排除。
STATIX=$(statix check -o errfmt "$ROOT" 2>/dev/null | wc -l | tr -d ' ' || true)
DEADNIX=$(deadnix --exclude="$ROOT/pkgs/_sources" "$ROOT" 2>/dev/null | grep -c 'Unused' | tr -d ' ' || true)
STATIX="${STATIX:-0}"
DEADNIX="${DEADNIX:-0}"

echo "statix : $STATIX (上限 $MAX_STATIX)"
echo "deadnix: $DEADNIX (上限 $MAX_DEADNIX)"

rc=0
if [ "$STATIX" -gt "$MAX_STATIX" ]; then
  echo >&2
  echo "statix 发现数从 $MAX_STATIX 涨到 ${STATIX}。" >&2
  echo "要么修掉新增的，要么在 flake.nix 的 lint-ratchet 检查里调低上限并说明理由。" >&2
  statix check "$ROOT" 2>/dev/null | head -40 >&2 || true
  rc=1
fi
if [ "$DEADNIX" -gt "$MAX_DEADNIX" ]; then
  echo >&2
  echo "deadnix 发现数从 $MAX_DEADNIX 涨到 ${DEADNIX}。" >&2
  echo '多数是未使用的函数参数，deadnix --edit --exclude=pkgs/_sources . 能直接修。' >&2
  deadnix --exclude="$ROOT/pkgs/_sources" "$ROOT" 2>/dev/null | head -40 >&2 || true
  rc=1
fi

if [ "$rc" -eq 0 ]; then
  if [ "$STATIX" -lt "$MAX_STATIX" ] || [ "$DEADNIX" -lt "$MAX_DEADNIX" ]; then
    echo
    echo "发现数已低于上限，可以把 flake.nix 里的上限收紧到 $STATIX / ${DEADNIX}。"
  fi
fi
exit "$rc"

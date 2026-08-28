#!/usr/bin/env bash
# 检查是否有 .nix 文件引用了未在 flake inputs 里声明的 input。
#
# 这条检查存在的理由：commit 353f738f（2025-10-11 "fix: types"）从 inputs 里删掉了
# hyprland / hyprpanel / plasma-manager 等 6 个 input，却只修了 darwin 配置的引用，
# 导致全部 8 个 nixosConfigurations 无法求值，且这个状态存活了十个月。
# 本检查耗时约 0.3 秒且无需求值，当时就能在 commit 时拦住它。
#
# 用法:
#   check-undeclared-inputs.sh                        # 自己用 nix flake metadata 取名单
#   check-undeclared-inputs.sh <名单文件> [<仓库根>]   # 名单由调用方提供（沙箱内用这个）
set -euo pipefail

declared_file="${1:-}"
root="${2:-.}"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -n "$declared_file" ]; then
  sort -u "$declared_file" >"$tmp/declared"
else
  {
    nix flake metadata --json "$root" | jq -r '.locks.nodes.root.inputs | keys[]'
    echo self
  } | sort -u >"$tmp/declared"
fi

# 先剥掉行内注释（^[^#]*），再抓 inputs.<name>。
# 边界必须排除连字符和点，否则文件名 check-undeclared-inputs.sh 里的
# "inputs.sh" 会被 \binputs\. 匹配成一个叫 sh 的 input（\b 在连字符后成立）。
grep -rh --include='*.nix' -oE '^[^#]*' "$root" 2>/dev/null |
  grep -ohE '(^|[^-[:alnum:]_.])inputs\.[[:alnum:]_-]+' |
  sed -E 's/.*inputs\.//' |
  grep -v '^[[:space:]]*$' |
  sort -u >"$tmp/used"

missing=$(comm -23 "$tmp/used" "$tmp/declared" | grep -v '^[[:space:]]*$' || true)

if [ -n "$missing" ]; then
  echo "以下 flake input 被引用但未声明：" >&2
  echo "$missing" | sed 's/^/  - /' >&2
  echo >&2
  echo "引用位置：" >&2
  while IFS= read -r name; do
    grep -rn --include='*.nix' "inputs\.${name}\b" "$root" 2>/dev/null |
      grep -v '^[[:space:]]*#' | sed 's/^/  /' >&2 || true
  done <<<"$missing"
  exit 1
fi

echo "OK: 所有被引用的 flake input 都已声明"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
workspace=$PWD
if [[ ${1:-} != --session ]]; then
  for executable in kwin_wayland kitty dbus-run-session busctl; do
    command -v "$executable" >/dev/null
  done
  test -f packages/kwin/dist/krohnkite.js
  temporary=$(mktemp -d /tmp/krohnkite-rewrite-nested.XXXXXX)
  cleanup_outer() {
    local status=$?
    mkdir -p "$workspace/dist"
    if [[ -f "$temporary/kwin.log" ]]; then cp "$temporary/kwin.log" "$workspace/dist/kwin-smoke.log"; fi
    case "$temporary" in /tmp/krohnkite-rewrite-nested.??????) rm -rf -- "$temporary" ;; *) status=1 ;; esac
    exit "$status"
  }
  trap cleanup_outer EXIT
  mkdir -p "$temporary/config" "$temporary/data" "$temporary/cache"
  XDG_CONFIG_HOME="$temporary/config" XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    dbus-run-session -- bash "$workspace/scripts/kwin-smoke.sh" --session "$temporary"
  exit 0
fi

temporary=$2
socket="krohnkite-rewrite-test-$$"
kitty_pids=()
kwin_pid=""
namespace=krohnkite-rewrite-validation
loaded=false
padding_counter=0
start_line=0
failure_pattern='KROHNKITE_REWRITE_KWIN_(FAILED|LOG)|ReferenceError.*(scriptRoot|root)|QQmlContext'
cleanup_session() {
  local status=$?
  trap - EXIT
  if "$loaded" && [[ -n "$kwin_pid" ]] && kill -0 "$kwin_pid" 2>/dev/null; then
    busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting unloadScript s "$namespace" >/dev/null 2>&1 || true
  fi
  for pid in "${kitty_pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  if [[ -n "$kwin_pid" ]]; then kill "$kwin_pid" 2>/dev/null || true; wait "$kwin_pid" 2>/dev/null || true; fi
  exit "$status"
}
trap cleanup_session EXIT
export QT_FORCE_STDERR_LOGGING=1
export QT_LOGGING_RULES='*.debug=false;qml.debug=true;*.warning=true;*.critical=true;qt.qml.usedbeforedeclared.warning=false'
kwin_wayland --virtual --width 1280 --height 800 --no-lockscreen --no-global-shortcuts --no-kactivities --socket "$socket" > "$temporary/kwin.log" 2>&1 &
kwin_pid=$!
for attempt in $(seq 1 60); do
  if [[ -S "$XDG_RUNTIME_DIR/$socket" ]] && busctl --user status org.kde.KWin >/dev/null 2>&1; then break; fi
  if ! kill -0 "$kwin_pid" 2>/dev/null; then cat "$temporary/kwin.log"; exit 1; fi
  sleep 0.25
done

scripting() {
  busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting "$@"
}
numeric_id() {
  local result=$1 id
  case "$result" in 'i '*) ;; *) return 1 ;; esac
  id=${result#i }
  case "$id" in ''|*[!0-9]*) return 1 ;; esac
  printf '%s\n' "$id"
}
reserve_ids() {
  # KWin allocates scripts.size(), so a gap below an existing D-Bus path can
  # reuse an occupied ID. Inert padding is retained until this compositor exits.
  local tree path suffix max_id=-1 count=0 result padding_id name attempt
  tree=$(busctl --user --list tree org.kde.KWin) || return 1
  while IFS= read -r path; do
    case "$path" in /Scripting/Script*) ;; *) continue ;; esac
    suffix=${path#/Scripting/Script}
    case "$suffix" in ''|*[!0-9]*) continue ;; esac
    count=$((count + 1))
    if (( suffix > max_id )); then max_id=$suffix; fi
  done <<< "$tree"
  if (( count > max_id )); then return 0; fi
  printf '// Reserved ID only; never run.\n' > "$temporary/id-padding.js"
  for attempt in $(seq 1 100); do
    padding_counter=$((padding_counter + 1))
    name="krohnkite-rewrite-id-padding-$$-$padding_counter"
    result=$(scripting loadScript ss "$temporary/id-padding.js" "$name") || return 1
    padding_id=$(numeric_id "$result") || return 1
    if (( padding_id >= max_id )); then return 0; fi
  done
  printf 'KWin script ID reservation exceeded its limit\n' >&2
  return 1
}
cycle_has() {
  grep -qE "$1" < <(tail -n "+$((start_line + 1))" "$temporary/kwin.log")
}
wait_marker() {
  local marker=$1 attempt
  for attempt in $(seq 1 100); do
    if cycle_has "$failure_pattern"; then return 1; fi
    if cycle_has "$marker"; then return 0; fi
    if ! kill -0 "$kwin_pid" 2>/dev/null; then return 1; fi
    sleep 0.2
  done
  return 1
}
wait_unloaded() {
  local attempt
  for attempt in $(seq 1 40); do
    if [[ $(scripting isScriptLoaded s "$namespace") == 'b false' ]]; then return 0; fi
    sleep 0.05
  done
  return 1
}

for cycle in 1 2; do
  start_line=$(wc -l < "$temporary/kwin.log")
  reserve_ids
  # Both cycles load the exact same QML and JavaScript URLs in one engine.
  result=$(scripting loadDeclarativeScript ss "$workspace/tests/qml/kwin.qml" "$namespace")
  id=$(numeric_id "$result")
  loaded=true
  busctl --user call org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script run
  if (( cycle == 1 )); then
    for number in 1 2; do
      WAYLAND_DISPLAY="$socket" kitty -o linux_display_server=wayland --title "Krohnkite rewrite check $number" --hold printf 'Krohnkite Effect check %s\n' "$number" > "$temporary/kitty-$number.log" 2>&1 &
      kitty_pids+=("$!")
    done
  fi
  if ! wait_marker 'KROHNKITE_REWRITE_KWIN_OK'; then
    cat "$temporary/kwin.log" "$temporary/kitty-1.log" "$temporary/kitty-2.log"
    exit 1
  fi
  kill -0 "$kwin_pid"
  scripting unloadScript s "$namespace"
  if ! wait_marker 'KROHNKITE_REWRITE_KWIN_DISPOSE_OK' || ! wait_unloaded; then
    cat "$temporary/kwin.log"
    exit 1
  fi
  loaded=false
  kill -0 "$kwin_pid"
done

# Closing the same windows after both importing contexts are gone also emits
# removal/geometry signals and exposes any stale Qt callback connections.
for pid in "${kitty_pids[@]}"; do kill "$pid" 2>/dev/null || true; done
for pid in "${kitty_pids[@]}"; do wait "$pid" 2>/dev/null || true; done
kitty_pids=()
sleep 0.5
kill -0 "$kwin_pid"
if grep -qE "$failure_pattern" "$temporary/kwin.log"; then
  cat "$temporary/kwin.log"
  exit 1
fi
grep 'KROHNKITE_REWRITE_KWIN_' "$temporary/kwin.log"

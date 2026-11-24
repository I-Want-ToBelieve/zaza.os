#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
workspace=$PWD

usage() {
  printf 'Usage: bash scripts/kwin-config-smoke.sh [--package /absolute/installed/script/directory]\n'
}

if [[ ${1:-} != --session ]]; then
  package=""
  if [[ ${1:-} == --help ]]; then usage; exit 0; fi
  if (( $# > 0 )); then
    if [[ $# != 2 || $1 != --package ]]; then usage >&2; exit 2; fi
    package=$2
    case "$package" in /*) ;; *) printf 'The package directory must be absolute\n' >&2; exit 2 ;; esac
    for file in metadata.json contents/ui/main.qml contents/code/krohnkite.js; do
      test -r "$package/$file"
    done
  else
    test -r packages/kwin/dist/krohnkite.js
  fi
  for executable in kwin_wayland kitty dbus-run-session busctl kwriteconfig6; do
    command -v "$executable" >/dev/null
  done
  temporary=$(mktemp -d /tmp/krohnkite-file-config.XXXXXX)
  cleanup_outer() {
    local status=$?
    trap - EXIT
    mkdir -p "$workspace/dist"
    for log in kwin.log kitty-1.log kitty-2.log; do
      if [[ -f "$temporary/$log" ]]; then cp "$temporary/$log" "$workspace/dist/kwin-config-smoke-$log"; fi
    done
    case "$temporary" in /tmp/krohnkite-file-config.??????) rm -rf -- "$temporary" ;; *) status=1 ;; esac
    exit "$status"
  }
  trap cleanup_outer EXIT
  mkdir -p "$temporary/config" "$temporary/config-dirs" "$temporary/data" "$temporary/cache" "$temporary/package"
  cp "$workspace/tests/qml/file-configuration.qml" "$temporary/file-configuration.qml"
  if [[ -n "$package" ]]; then
    cp -aL "$package/." "$temporary/package/"
  else
    cp -aL "$workspace/packages/kwin/assets/." "$temporary/package/"
    mkdir -p "$temporary/package/contents/code"
    cp "$workspace/packages/kwin/dist/krohnkite.js" "$temporary/package/contents/code/krohnkite.js"
  fi
  # Store directories are readonly. Change only our dereferenced temporary copy
  # so ordinary users can remove it after the test; the installed package stays intact.
  chmod -R u+rwX "$temporary/package"
  XDG_CONFIG_HOME="$temporary/config" XDG_CONFIG_DIRS="$temporary/config-dirs" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    dbus-run-session -- bash "$workspace/scripts/kwin-config-smoke.sh" --session "$temporary"
  exit 0
fi

temporary=${2:?Missing session directory}
case "$temporary" in /tmp/krohnkite-file-config.??????) ;; *) exit 2 ;; esac
[[ $XDG_CONFIG_HOME == "$temporary/config" && $XDG_DATA_HOME == "$temporary/data" ]]
socket="krohnkite-file-config-$$"
namespace=krohnkite
kitty_pids=()
kwin_pid=""
loaded=false
failure_pattern='KROHNKITE_FILE_CONFIG_FAILED|ReferenceError|TypeError|QQmlContext|Component failed to load|module .* is not installed|KROHNKITE:.*(Error|readConfig)'

scripting() {
  busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting "$@"
}
cleanup_session() {
  local status=$?
  trap - EXIT
  if "$loaded" && [[ -n "$kwin_pid" ]] && kill -0 "$kwin_pid" 2>/dev/null; then
    scripting unloadScript s "$namespace" >/dev/null 2>&1 || true
  fi
  for pid in "${kitty_pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  for pid in "${kitty_pids[@]}"; do wait "$pid" 2>/dev/null || true; done
  if [[ -n "$kwin_pid" ]]; then kill "$kwin_pid" 2>/dev/null || true; wait "$kwin_pid" 2>/dev/null || true; fi
  exit "$status"
}
trap cleanup_session EXIT

write_config() {
  kwriteconfig6 --file kwinrc --group Script-krohnkite "$@"
}
set_gaps() {
  local side
  for side in Left Right Top Bottom Between; do write_config --key "screenGap$side" "$1"; done
}
reconfigure() {
  busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
}
reserve_ids() {
  # KWin allocates scripts.size(); pad any holes below an occupied D-Bus ID.
  # Padding scripts are never run and are retained until this compositor exits.
  local tree path suffix max_id=-1 count=0 result padding_id attempt
  tree=$(busctl --user --list tree org.kde.KWin)
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
    result=$(scripting loadScript ss "$temporary/id-padding.js" "krohnkite-file-config-padding-$$-$attempt")
    case "$result" in 'i '*) padding_id=${result#i } ;; *) return 1 ;; esac
    case "$padding_id" in ''|*[!0-9]*) return 1 ;; esac
    if (( padding_id >= max_id )); then return 0; fi
  done
  printf 'KWin script ID reservation exceeded its limit\n' >&2
  return 1
}
wait_marker() {
  local marker=$1 attempt
  for attempt in $(seq 1 120); do
    if grep -qE "$failure_pattern" "$temporary/kwin.log"; then return 1; fi
    if grep -q "$marker" "$temporary/kwin.log"; then return 0; fi
    if ! kill -0 "$kwin_pid" 2>/dev/null; then return 1; fi
    sleep 0.2
  done
  return 1
}
require_marker() {
  if ! wait_marker "$1"; then
    for log in kwin.log kitty-1.log kitty-2.log; do
      if [[ -f "$temporary/$log" ]]; then cat "$temporary/$log"; fi
    done
    return 1
  fi
}

# The production package is loaded manually below. Disabling auto-start prevents
# a globally installed copy from also running in this isolated KWin session.
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled --type bool false
set_gaps 8
write_config --key noTileBorder --type bool true
for key in floatUtility preventMinimize monocleMinimizeRest floatAsDefault floatSkipPagerWindows tileNothing; do
  write_config --key "$key" --type bool false
done
for key in ignoreClass ignoreTitle ignoreRole floatingClass floatingTitle; do write_config --key "$key" ''; done
write_config --key notificationDuration 0
write_config --key tileLayoutOrder 1

export QT_FORCE_STDERR_LOGGING=1
export QT_LOGGING_RULES='*.debug=false;qml.debug=true;*.warning=true;*.critical=true;qt.qml.usedbeforedeclared.warning=false'
kwin_wayland --virtual --width 1280 --height 800 --no-lockscreen --no-global-shortcuts --no-kactivities --socket "$socket" > "$temporary/kwin.log" 2>&1 &
kwin_pid=$!
ready=false
for attempt in $(seq 1 60); do
  if [[ -S "$XDG_RUNTIME_DIR/$socket" ]] && busctl --user status org.kde.KWin >/dev/null 2>&1; then ready=true; break; fi
  if ! kill -0 "$kwin_pid" 2>/dev/null; then cat "$temporary/kwin.log"; exit 1; fi
  sleep 0.25
done
if ! "$ready"; then cat "$temporary/kwin.log"; exit 1; fi

reserve_ids
result=$(scripting loadDeclarativeScript ss "$temporary/file-configuration.qml" "$namespace")
case "$result" in 'i '*) id=${result#i } ;; *) printf 'Unexpected script ID: %s\n' "$result" >&2; exit 1 ;; esac
case "$id" in ''|*[!0-9]*) printf 'Invalid script ID\n' >&2; exit 1 ;; esac
loaded=true
busctl --user call org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script run
for number in 1 2; do
  WAYLAND_DISPLAY="$socket" kitty -o linux_display_server=wayland --title "Krohnkite file configuration $number" --hold printf 'Native file configuration check %s\n' "$number" > "$temporary/kitty-$number.log" 2>&1 &
  kitty_pids+=("$!")
done
require_marker KROHNKITE_FILE_CONFIG_INITIAL_OK
set_gaps 16
reconfigure
require_marker KROHNKITE_FILE_CONFIG_RELOAD_OK
write_config --key screenGapLeft not-a-number
reconfigure
require_marker KROHNKITE_FILE_CONFIG_INVALID_VALUE_OK
write_config --key screenGapLeft --delete
reconfigure
require_marker KROHNKITE_FILE_CONFIG_MISSING_KEY_OK
set_gaps 8
reconfigure
require_marker KROHNKITE_FILE_CONFIG_OK
scripting unloadScript s "$namespace"
unloaded=false
for attempt in $(seq 1 40); do
  if [[ $(scripting isScriptLoaded s "$namespace") == 'b false' ]]; then unloaded=true; break; fi
  sleep 0.05
done
if ! "$unloaded"; then printf 'Script did not unload\n' >&2; exit 1; fi
loaded=false
for pid in "${kitty_pids[@]}"; do kill "$pid" 2>/dev/null || true; done
for pid in "${kitty_pids[@]}"; do wait "$pid" 2>/dev/null || true; done
kitty_pids=()
sleep 0.5
kill -0 "$kwin_pid"
if grep -qE "$failure_pattern" "$temporary/kwin.log"; then cat "$temporary/kwin.log"; exit 1; fi
grep 'KROHNKITE_FILE_CONFIG_' "$temporary/kwin.log"

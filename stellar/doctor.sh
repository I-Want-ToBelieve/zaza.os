#!/usr/bin/env bash
# Inspect only the invoking user's current session. No repairs or service activation.
set -u
set -o pipefail

usage() {
  printf '%s\n' \
    'Usage: stellar-doctor [--help]' \
    '' \
    'Run inside a terminal in the Stellar graphical session. Checks Wayland, the' \
    'KineticWE/Noctalia processes, user services, D-Bus ownership and Noctalia config.' \
    'Prints log locations, never log contents or GUI override values. No repairs run.' \
    '' \
    'Exit status: 0 = checks passed (warnings may remain), 1 = session/config failure,' \
    '             2 = invalid arguments or missing diagnostic dependencies.'
}

if [[ $# -eq 1 && $1 == --help ]]; then
  usage
  exit 0
fi
if [[ $# -ne 0 ]]; then
  usage >&2
  exit 2
fi

for dependency in id ps readlink timeout systemctl busctl noctalia; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    printf '[FAIL] Missing dependency: %s\n' "$dependency" >&2
    exit 2
  fi
done

failures=0
warnings=0
pass() { printf '[ OK ] %s\n' "$*"; }
fail() {
  printf '[FAIL] %s\n' "$*"
  failures=$((failures + 1))
}
warn() {
  printf '[WARN] %s\n' "$*"
  warnings=$((warnings + 1))
}

printf 'Stellar session diagnostics\n'
printf 'Scope: the current user and current graphical session.\n\n'

if [[ -z ${XDG_RUNTIME_DIR:-} ]]; then
  fail 'XDG_RUNTIME_DIR is unset; run this from a terminal inside Stellar.'
elif [[ ! -d $XDG_RUNTIME_DIR || ! -O $XDG_RUNTIME_DIR || ! -w $XDG_RUNTIME_DIR ]]; then
  fail 'XDG_RUNTIME_DIR must be an accessible directory owned by the current user.'
else
  pass 'XDG_RUNTIME_DIR is accessible and owned by the current user.'
fi

if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
  fail 'WAYLAND_DISPLAY is unset; this terminal is not attached to a Wayland session.'
else
  case $WAYLAND_DISPLAY in
  /*) wayland_socket=$WAYLAND_DISPLAY ;;
  *) wayland_socket=${XDG_RUNTIME_DIR:-}/$WAYLAND_DISPLAY ;;
  esac
  if [[ -S $wayland_socket ]]; then
    pass 'The configured Wayland socket exists.'
  else
    fail 'The configured Wayland socket is missing or is not a socket.'
  fi
fi

# ps selects only this UID. /proc/PID/exe gives the full executable name, unlike
# pgrep's truncated comm field; shell wrappers and supervisor loops do not count.
kineticwe_count=0
noctalia_count=0
if current_uid=$(id -u) && user_pids=$(ps -u "$current_uid" -o pid= 2>/dev/null); then
  while IFS= read -r process_id; do
    process_id=${process_id//[[:space:]]/}
    [[ $process_id =~ ^[0-9]+$ ]] || continue
    executable=$(readlink "/proc/$process_id/exe" 2>/dev/null) || continue
    executable=${executable% (deleted)}
    case ${executable##*/} in
    kinetic-we | .kinetic-we-wrapped) kineticwe_count=$((kineticwe_count + 1)) ;;
    noctalia | .noctalia-wrapped) noctalia_count=$((noctalia_count + 1)) ;;
    esac
  done <<<"$user_pids"
  for process_name in KineticWE Noctalia; do
    if [[ $process_name == KineticWE ]]; then
      process_count=$kineticwe_count
    else
      process_count=$noctalia_count
    fi
    if [[ $process_count -eq 1 ]]; then
      pass "$process_name: exactly one process for the current user."
    else
      fail "$process_name: expected one process, found $process_count."
    fi
  done
else
  fail 'Could not enumerate the current user processes.'
fi

for target in kineticwe-workspace.target graphical-session.target; do
  if timeout 5s systemctl --user --quiet is-active "$target" >/dev/null 2>&1; then
    pass "$target is active."
  else
    fail "$target is inactive or the user service manager is unavailable."
  fi
done

if failed_units=$(timeout 5s systemctl --user --failed --no-legend --plain --no-pager 2>/dev/null); then
  if [[ -z $failed_units ]]; then
    pass 'No failed systemd user units.'
  else
    fail 'Failed systemd user units are present (unit names only):'
    while read -r unit_name _; do
      [[ -n $unit_name ]] && printf '       %s\n' "$unit_name"
    done <<<"$failed_units"
  fi
else
  fail 'Could not read failed units from the user service manager.'
fi

# Query the bus daemon rather than a service; this does not activate a missing
# notification daemon or portal and therefore preserves the state being tested.
for bus_name in \
  org.freedesktop.Notifications \
  org.freedesktop.portal.Desktop \
  org.freedesktop.impl.portal.desktop.kde; do
  if owner_reply=$(timeout 5s busctl --user --timeout=4s call \
    org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
    NameHasOwner s "$bus_name" 2>/dev/null); then
    if [[ $owner_reply == 'b true' ]]; then
      pass "$bus_name has a D-Bus owner."
    else
      fail "$bus_name has no D-Bus owner."
    fi
  else
    fail "Could not query D-Bus ownership for $bus_name."
  fi
done

stellar_home=${HOME:-}
if [[ -z $stellar_home ]]; then
  fail 'HOME is unset; cannot locate user configuration or logs.'
else
  config_dir=${XDG_CONFIG_HOME:-$stellar_home/.config}/noctalia
  state_file=${XDG_STATE_HOME:-$stellar_home/.local/state}/noctalia/settings.toml
  if [[ -f $state_file ]]; then
    warn 'GUI override state exists and may override the declarative config; values were not read.'
  else
    pass 'No GUI settings override file exists.'
  fi

  if [[ ! -d $config_dir ]]; then
    fail 'The Noctalia config directory is missing; the shell may be using upstream defaults.'
  else
    if [[ ! -f $config_dir/config.toml ]]; then
      fail 'The declared config.toml is missing; verify the Stellar Home Manager profile.'
    fi
    # Exactly one native validation. Suppress diagnostics because they can quote
    # user config values; report the status and provide the command for local use.
    if timeout 20s noctalia config validate "$config_dir" >/dev/null 2>&1; then
      pass 'Noctalia configuration validation passed.'
    else
      validation_status=$?
      fail "Noctalia configuration validation failed (exit $validation_status)."
      printf '       Run locally for details: noctalia config validate %q\n' "$config_dir"
    fi
  fi

  printf '\nLog locations (contents not read):\n'
  printf '  Noctalia: %q\n' "${XDG_CACHE_HOME:-$stellar_home/.cache}/noctalia/noctalia.log"
  if session_user=$(id -un 2>/dev/null); then
    printf '  KineticWE launcher: %q\n' "${XDG_RUNTIME_DIR:-/tmp}/kineticwe-$session_user/session.log"
  fi
  printf '  KDE portal: %q\n' "$stellar_home/.local/share/xdg-desktop-portal-kde.log"
  printf '  Portal frontend: %q\n' "$stellar_home/.local/share/xdg-desktop-portal.log"
  printf '  User service journal: journalctl --user -b\n'
  printf '  Session output / greetd journal: journalctl -b -u greetd\n'
fi

printf '\nResult: %s failure(s), %s warning(s).\n' "$failures" "$warnings"
if [[ $failures -gt 0 ]]; then
  exit 1
fi
exit 0

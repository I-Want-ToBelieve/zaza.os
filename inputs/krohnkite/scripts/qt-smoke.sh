#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
qt_runner=""
for candidate in /usr/lib/qt6/bin/qml /usr/lib/qt6/bin/qmlscene qml6 qml-qt6; do
  if command -v "$candidate" >/dev/null 2>&1; then
    qt_runner="$candidate"
    break
  fi
done
if [[ -z "$qt_runner" ]]; then
  echo 'Qt 6 QML runner missing; Ubuntu: apt-get install qml-qt6 qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtqml-models qml6-module-qtqml-workerscript' >&2
  exit 1
fi
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_FORCE_STDERR_LOGGING=1 \
  QT_LOGGING_RULES='*.debug=false;qml.debug=true;*.warning=true;*.critical=true;qt.qml.usedbeforedeclared.warning=false' \
  timeout 20s "$qt_runner" tests/qml/runtime.qml

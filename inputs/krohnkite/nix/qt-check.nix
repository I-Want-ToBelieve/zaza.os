{
  runCommand,
  kdePackages,
  coreutils,
  krohnkite,
}:
runCommand "krohnkite-qt-runtime" {
  nativeBuildInputs = [kdePackages.qtdeclarative coreutils];
} ''
  mkdir -p tests/qml packages/kwin/dist
  cp ${krohnkite.src}/tests/qml/runtime.qml tests/qml/runtime.qml
  cp ${krohnkite}/share/kwin/scripts/krohnkite/contents/code/krohnkite.js packages/kwin/dist/krohnkite.js
  export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_FORCE_STDERR_LOGGING=1
  export QT_LOGGING_RULES='*.debug=false;qml.debug=true;*.warning=true;*.critical=true;qt.qml.usedbeforedeclared.warning=false'
  export QML_IMPORT_PATH=${kdePackages.qtdeclarative}/lib/qt-6/qml
  timeout 20 qml tests/qml/runtime.qml
  touch "$out"
''

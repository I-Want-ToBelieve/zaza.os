{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "fcitx5-tahoe-theme";
  version = "2026-09-13";
  src = ./themes;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/fcitx5/themes" "$out/share/licenses/fcitx5-tahoe-theme"
    cp -r Tahoe-Light Tahoe-Dark "$out/share/fcitx5/themes/"
    cp ${./LICENSE} "$out/share/licenses/fcitx5-tahoe-theme/LICENSE"
    runHook postInstall
  '';
  meta = {
    description = "Tahoe-style Fcitx5 candidate panel adapted from Fcitx5-MacOS-Theme";
    homepage = "https://github.com/Become-ILLUSORY/Fcitx5-MacOS-Theme";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}

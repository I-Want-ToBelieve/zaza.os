{
  lib,
  stdenvNoCC,
  mactahoeKdeSrc,
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-kde";
  version = "unstable-${builtins.substring 0 8 mactahoeKdeSrc.lastModifiedDate}";
  src = mactahoeKdeSrc;
  dontBuild = true;
  # Only images, QML, JavaScript and metadata; no executable fixups are needed.
  dontFixup = true;
  installPhase = ''
    runHook preInstall
    # Upstream install.sh writes some paths outside --dest and branches on UID.
    # Install only resources into the store; plasma-manager owns the layout.
    mkdir -p "$out/share/"{color-schemes,plasma/desktoptheme,plasma/look-and-feel,Kvantum,wallpapers,aurorae/themes}
    mkdir -p "$out/share/doc/mactahoe-kde"
    cp LICENSE AUTHORS "$out/share/doc/mactahoe-kde/"
    cp -r color-schemes/*.colors "$out/share/color-schemes/"
    cp -r Kvantum/MacTahoe "$out/share/Kvantum/"
    cp -r wallpapers/MacTahoe* "$out/share/wallpapers/"
    cp -r plasma/look-and-feel/* "$out/share/plasma/look-and-feel/"
    for variant in Light Dark; do
      name="MacTahoe-$variant"
      cp -r "plasma/desktoptheme/$name" "$out/share/plasma/desktoptheme/"
      cp -r plasma/desktoptheme/icons "$out/share/plasma/desktoptheme/$name/"
      for scale in "" -1.25x -1.5x; do
        theme="$name$scale"
        dest="$out/share/aurorae/themes/$theme"
        mkdir -p "$dest"
        cp "aurorae/$theme/"*.svg "aurorae/icons-$variant/"*.svg "$dest/"
        cp "aurorae/''${variant}rc" "$dest/''${theme}rc"
        for metadata in metadata.desktop metadata.json; do
          sed "s/theme_name/$theme/g" "aurorae/$metadata" > "$dest/$metadata"
        done
      done
    done
    runHook postInstall
  '';
  meta = {
    description = "MacTahoe Plasma, Aurorae, Kvantum and wallpaper resources";
    homepage = "https://github.com/vinceliuice/MacTahoe-kde";
    license = with lib.licenses; [lgpl3Only gpl3Only];
    platforms = lib.platforms.linux;
  };
}

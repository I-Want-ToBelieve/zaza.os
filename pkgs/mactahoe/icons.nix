{
  lib,
  stdenvNoCC,
  gtk3,
  mactahoeIconsSrc,
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-icons";
  version = "unstable-${builtins.substring 0 8 mactahoeIconsSrc.lastModifiedDate}";
  src = mactahoeIconsSrc;
  nativeBuildInputs = [gtk3];
  dontBuild = true;
  # Avoid scanning thousands of SVG/Xcursor resources as executable programs.
  dontFixup = true;
  installPhase = ''
    runHook preInstall
    # Includes prebuilt Xcursor and scalable cursors; no graphics tools needed.
    # stdenv exports name; explicitly override it so resource IDs stay MacTahoe.
    bash install.sh --dest "$out/share/icons" --name MacTahoe --theme default
    runHook postInstall
  '';
  meta = {
    description = "MacTahoe icons and cursors (default color, light and dark)";
    homepage = "https://github.com/vinceliuice/MacTahoe-icon-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}

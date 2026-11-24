{
  lib,
  stdenvNoCC,
  sassc,
  glib,
  libxml2,
  mactahoeGtkSrc,
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-gtk-theme";
  version = "unstable-${builtins.substring 0 8 mactahoeGtkSrc.lastModifiedDate}";
  src = mactahoeGtkSrc;
  nativeBuildInputs = [sassc glib libxml2];
  dontBuild = true;
  dontFixup = true;

  postPatch = ''
    # Upstream assumes a login account and sudo, and installs a theme-switcher
    # outside --dest. The Nix build supplies dependencies and only emits assets.
    substituteInPlace libs/lib-core.sh \
      --replace-fail 'MY_HOME=$(getent passwd "''${MY_USERNAME}" | cut -d: -f6)' 'MY_HOME="$HOME"' \
      --replace-fail 'SUDO_BIN="$(command -v sudo)"' 'SUDO_BIN=""'
    substituteInPlace install.sh \
      --replace-fail 'full_sudo "''${1}"; silent_mode=' 'silent_mode=' \
      --replace-fail '  install_app' '  # Theme selection is managed by Home Manager.'
  '';

  installPhase = ''
    runHook preInstall
    export HOME="$TMPDIR/mactahoe-home"
    mkdir -p "$HOME" "$out/share/themes" "$out/share/doc/mactahoe-gtk-theme"
    # --silent-mode permits only one color/opacity per invocation.
    for color in light dark; do
      for opacity in normal solid; do
        bash install.sh --silent-mode --dest "$out/share/themes" --name MacTahoe \
          --color "$color" --opacity "$opacity"
      done
    done
    cp COPYING "$out/share/doc/mactahoe-gtk-theme/"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    for color in Light Dark; do
      for opacity in "" -solid; do
        theme="$out/share/themes/MacTahoe-$color$opacity"
        test -s "$theme/index.theme"
        test -s "$theme/gtk-2.0/gtkrc"
        for version in 3.0 4.0; do
          test -s "$theme/gtk-$version/gtk.css"
          test -s "$theme/gtk-$version/gtk-dark.css"
          test -d "$theme/gtk-$version/assets"
        done
      done
    done
    test ! -e "$out/bin/gnome-theme-switcher"
    runHook postInstallCheck
  '';

  meta = {
    description = "MacTahoe GTK themes (light/dark, normal/solid)";
    homepage = "https://github.com/vinceliuice/MacTahoe-gtk-theme";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}

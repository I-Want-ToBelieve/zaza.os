# https://github.com/a-parhom/LightlyShaders/issues/107
{ lib, stdenv, cmake, extra-cmake-modules, libsForQt5, libepoxy, sources, }:
let inherit (sources.lightly-shaders) pname src version;
in stdenv.mkDerivation {
  inherit pname src version;

  nativeBuildInputs = [ cmake extra-cmake-modules ];

  buildInputs = [
    libsForQt5.kwindowsystem
    libsForQt5.plasma-framework
    libsForQt5.systemsettings
    libsForQt5.kdecoration
    libsForQt5.kinit
    libsForQt5.kwin
    libepoxy
    libsForQt5.kdelibs4support
    libsForQt5.qt5.wrapQtAppsHook
  ];

  postConfigure = ''
    substituteInPlace cmake_install.cmake \
      --replace "${libsForQt5.kdelibs4support}" "$out"
  '';

  meta = with lib; {
    description =
      "This version has almost zero performance impact, as well as correctly works with stock Plasma effects";
    license = licenses.mit;
    homepage = "https://github.com/a-parhom/LightlyShaders";
    inherit (libsForQt5.kwindowsystem.meta) platforms;
  };
}

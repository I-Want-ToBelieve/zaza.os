{ mkDerivation, cmake, extra-cmake-modules, plasma-framework, mpv, qtdeclarative
, qtx11extras, vulkan-headers, vulkan-loader, vulkan-tools, pkg-config, lz4
, sources, pkgs, }:
let inherit (sources.wallpaper-engine-kde-plugin) pname src version;
in mkDerivation {
  inherit pname src version;

  cmakeFlags = [ "-DUSE_PLASMAPKG=OFF" ];

  nativeBuildInputs = [ cmake extra-cmake-modules pkg-config ];

  buildInputs = [
    pkgs.gst_all_1.gst-libav
    plasma-framework
    mpv
    qtdeclarative
    qtx11extras
    lz4
    vulkan-headers
    vulkan-tools
    vulkan-loader
  ];

  propagatedBuildInputs = [
    pkgs.libsForQt5.qt5.qtwebsockets
    pkgs.libsForQt5.qt5.qtwebchannel
    (pkgs.python3Full.withPackages (ps:
      with ps;
      [
        websockets
        # other python packages
      ]))
  ];
}

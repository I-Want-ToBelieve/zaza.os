{
  stdenv,
  cmake,
  protobuf,
  tclap,
  hdf5,
  curl,
  c-ares,
  python3,
  qt6,
  sources,
  lib,
}: let
  inherit (sources.ecal) pname src version;
in
  stdenv.mkDerivation {
    inherit pname src version;

    nativeBuildInputs = [cmake];
    buildInputs = [protobuf tclap hdf5 curl c-ares python3 qt6.full];

    configurePhase = ''
      mkdir -p _build
      cd _build
      cmake -E env CXXFLAGS="-Wno-error=restrict"
      cmake .. -DCMAKE_INSTALL_PREFIX=$out/usr \
               -DCMAKE_BUILD_TYPE=Release \
               -DBUILD_PY_BINDING=ON \
               -DBUILD_STANDALONE_PY_WHEEL=ON \
               -DECAL_THIRDPARTY_BUILD_PROTOBUF=OFF \
               -DECAL_THIRDPARTY_BUILD_CURL=OFF \
               -DECAL_THIRDPARTY_BUILD_HDF5=OFF \
               -DCMAKE_INSTALL_SYSCONFDIR=$out/etc \
               -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON
    '';

    installPhase = ''
      cd _build
      DESTDIR="$out" make install
      cd python
      python -m build --wheel --no-isolation
      python -m installer --destdir="$out" dist/*.whl
    '';

    meta = {
      description = "eCAL - enhanced Communication Abstraction Layer";
      homepage = "https://github.com/eclipse-ecal/ecal";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [];
    };
  }

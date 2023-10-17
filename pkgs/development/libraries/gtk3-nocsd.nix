{ stdenv, pkg-config, gtk3, gobject-introspection, sources, }:
let inherit (sources.gtk3-nocsd) pname src version;
in stdenv.mkDerivation {
  inherit pname src version;

  buildInputs = [ gtk3 gobject-introspection ];

  nativeBuildInputs = [ pkg-config ];

  makeFlags = [ "prefix=${placeholder "out"}" ];
}

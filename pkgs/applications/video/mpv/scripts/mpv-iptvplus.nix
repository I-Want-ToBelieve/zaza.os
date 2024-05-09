# @see https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/video/mpv/scripts/uosc.nix#L43
# @see https://github.com/pintassilgo/mpv-iptvplus/tree/master
{ stdenvNoCC, lib, sources, }:
let inherit (sources.mpv-iptvplus) pname src version;
in stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname src version;

  postPatch = ''
    substituteInPlace iptv.lua \
      --replace "window=24" "window=18"
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mpv/scripts
    cp iptv.lua $out/share/mpv/scripts

    runHook postInstall
  '';

  passthru.scriptName = "iptv.lua";

  meta = with lib; {
    description = "iptv script for mpv";
    homepage = "https://github.com/pintassilgo/mpv-iptvplus";
    license = licenses.gpl3Only;
  };
})

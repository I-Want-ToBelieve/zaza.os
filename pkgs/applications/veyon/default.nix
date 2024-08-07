{
  lib,
  stdenv,
  fetchFromGitHub,
  writeText,
  libsForQt5,
  cmake,
  pkg-config,
  lzo,
  openldap,
  cyrus_sasl,
  pam,
  procps,
  libXtst,
  libXrandr,
  libXinerama,
  libXdamage,
  libXcursor,
  libvncserver,
  libfakekey,
}: let
  # Replace CONTRIBUTOR list with link to upstream
  # This avoids generating contibutor list at build-time
  contributors = writeText "CONTRIBUTORS" ''
    https://github.com/veyon/veyon/contributors
  '';
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "veyon";
    version = "4.8.3";

    src = fetchFromGitHub {
      owner = "veyon";
      repo = "veyon";
      rev = "v${finalAttrs.version}";
      hash = "sha256-DubIQTh6i+ugCLxdpWN+xUeXrgmjYdAODM4imJDBpmk=";
      fetchSubmodules = true; # kldap, x11vnc and qthttpserver get built from source
    };

    patches = [./fix-install-perms.patch];

    nativeBuildInputs = [
      cmake
      pkg-config
      libsForQt5.wrapQtAppsHook
    ];

    cmakeFlags = [
      # cmake's setup hook makes it so that this is absolute by default
      # veyon's build steps only work if this is relative
      (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
      (lib.cmakeFeature "SYSTEMD_SERVICE_INSTALL_DIR" "lib/systemd/system")
      (lib.cmakeFeature "CONTRIBUTORS" "${contributors}")
    ];

    buildInputs = [
      libsForQt5.qttools
      libsForQt5.qca
      lzo
      openldap
      cyrus_sasl
      pam
      procps
      libXtst
      libXrandr
      libXinerama
      libXdamage
      libXcursor
      libvncserver
      libfakekey
    ];

    # Some executables need to access the other ones
    qtWrapperArgs = ["--prefix PATH : ${placeholder "out"}/bin"];

    meta = {
      changelog = "https://github.com/veyon/veyon/releases/tag/${finalAttrs.src.rev}";
      description = "A free and open source software for monitoring and controlling computers across multiple platforms";
      homepage = "https://veyon.io";
      license = lib.licenses.gpl2Only;
      mainProgram = "veyon-master";
      maintainers = with lib.maintainers; [tomasajt];
      platforms = lib.platforms.linux;
    };
  })

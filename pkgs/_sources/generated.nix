# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools, }: {
  aliyunpan = {
    pname = "aliyunpan";
    version = "e91e66aadf6ce7db62ff3552dd905b238e911d00";
    src = fetchFromGitHub {
      owner = "tickstep";
      repo = "aliyunpan";
      rev = "e91e66aadf6ce7db62ff3552dd905b238e911d00";
      fetchSubmodules = false;
      sha256 = "sha256-Wg5996+obxtnTFZivKdRvaPQXKLzpLsFvCc2QO+0FUc=";
    };
    date = "2023-10-08";
  };
  gtk3-nocsd = {
    pname = "gtk3-nocsd";
    version = "512c2bd866d71def6ffd4d85ca98ae12fe989c62";
    src = fetchFromGitHub {
      owner = "ZaWertun";
      repo = "gtk3-nocsd";
      rev = "512c2bd866d71def6ffd4d85ca98ae12fe989c62";
      fetchSubmodules = false;
      sha256 = "sha256-BOsQqxaVdC5O6EnB3KZinKSj0U5mCcX8HSjRmSBUFks=";
    };
    date = "2021-06-23";
  };
  lightly-shaders = {
    pname = "lightly-shaders";
    version = "cea07c0996373e3a0eaf232f478ebff7a913af8f";
    src = fetchFromGitHub {
      owner = "a-parhom";
      repo = "LightlyShaders";
      rev = "cea07c0996373e3a0eaf232f478ebff7a913af8f";
      fetchSubmodules = false;
      sha256 = "sha256-l6UXgU2Xv57Ge9fO6tk5a6+mPG7zrxdm28FAOSRZnA4=";
    };
    date = "2023-03-29";
  };
  manix = {
    pname = "manix";
    version = "d08e7ca185445b929f097f8bfb1243a8ef3e10e4";
    src = fetchFromGitHub {
      owner = "mlvzk";
      repo = "manix";
      rev = "d08e7ca185445b929f097f8bfb1243a8ef3e10e4";
      fetchSubmodules = false;
      sha256 = "sha256-GqPuYscLhkR5E2HnSFV4R48hCWvtM3C++3zlJhiK/aw=";
    };
    date = "2021-04-20";
  };
  mpv-iptvplus = {
    pname = "mpv-iptvplus";
    version = "e4fde04bbad4573b94695df6409edf6e88ecdb3c";
    src = fetchFromGitHub {
      owner = "pintassilgo";
      repo = "mpv-iptvplus";
      rev = "e4fde04bbad4573b94695df6409edf6e88ecdb3c";
      fetchSubmodules = false;
      sha256 = "sha256-+LTp2eTVow+ib0/+8YZkxZ+X4LI8bFxT/i05XeEFBx8=";
    };
    date = "2023-01-04";
  };
  plasma5-applets-window-appmenu = {
    pname = "plasma5-applets-window-appmenu";
    version = "1de99c93b0004b80898081a1acfd1e0be807326a";
    src = fetchFromGitHub {
      owner = "psifidotos";
      repo = "applet-window-appmenu";
      rev = "1de99c93b0004b80898081a1acfd1e0be807326a";
      fetchSubmodules = false;
      sha256 = "sha256-PLlZ2qgdge8o1mZOiPOXSmTQv1r34IUmWTmYFGEzNTI=";
    };
    date = "2022-06-27";
  };
  swhkd = {
    pname = "swhkd";
    version = "111677251a649bd65cc036bca07ff7117696b1df";
    src = fetchFromGitHub {
      owner = "waycrate";
      repo = "swhkd";
      rev = "111677251a649bd65cc036bca07ff7117696b1df";
      fetchSubmodules = false;
      sha256 = "sha256-LxeLI7Sa3pcjW69YKDn49C91yDpRL9Vayx8ylA0XasM=";
    };
    cargoLock."Cargo.lock" = {
      lockFile = ./swhkd-111677251a649bd65cc036bca07ff7117696b1df/Cargo.lock;
      outputHashes = { };
    };
    date = "2023-09-22";
  };
  wallpaper-engine-kde-plugin = {
    pname = "wallpaper-engine-kde-plugin";
    version = "f972b2a24c9c3cc2d3e4f41d2ebd14f1473cebdf";
    src = fetchFromGitHub {
      owner = "catsout";
      repo = "wallpaper-engine-kde-plugin";
      rev = "f972b2a24c9c3cc2d3e4f41d2ebd14f1473cebdf";
      fetchSubmodules = true;
      sha256 = "sha256-BVtTnJA1RLUU/Tj7WI/80ja4pI8NezHCjKvB72VjrZk=";
    };
    date = "2023-08-06";
  };
}

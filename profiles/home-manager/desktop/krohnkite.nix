{
  inputs,
  lib,
  pkgs,
  ...
}: {
  # 实机和 VM 共用平铺行为，主题、面板和输入法由各自模块管理。
  programs.krohnkite = {
    enable = lib.mkDefault true;
    package = lib.mkDefault inputs.krohnkite.packages.${pkgs.stdenv.hostPlatform.system}.krohnkite;
    settings = {
      screenDefaultLayout = ":tile";
      screenGapBetween = 8;
      screenGapLeft = 8;
      screenGapRight = 8;
      screenGapTop = 8;
      screenGapBottom = 8;
      noTileBorder = false;
      soleWindowNoBorders = false;
      soleWindowNoGaps = false;
      floatUtility = true;
      # 保留上游默认过滤项，增加 lvlv 的启动器、截图和输入法窗口。
      ignoreClass = lib.concatStringsSep "," [
        "krunner"
        "yakuake"
        "spectacle"
        "kded5"
        "xwaylandvideobridge"
        "plasmashell"
        "ksplashqml"
        "org.kde.plasmashell"
        "org.kde.polkit-kde-authentication-agent-1"
        "org.freedesktop.impl.portal.desktop.kde"
        "org.kde.kruler"
        "kruler"
        "kwin_wayland"
        "ksmserver-logout-greeter"
        "vicinae"
        "flameshot"
        "org.flameshot.Flameshot"
        "fcitx"
        "fcitx5"
        "copyq"
        "com.github.hluk.copyq"
      ];
    };
    # 只用 Meta + 单键；保留启动器、终端、锁屏和显示桌面。
    shortcuts = {
      KrohnkiteFocusLeft = "Meta+Left";
      KrohnkiteFocusDown = "Meta+Down";
      KrohnkiteFocusUp = "Meta+Up";
      KrohnkiteFocusRight = "Meta+Right";
      KrohnkiteFocusNext = "Meta+End";
      KrohnkiteFocusPrev = "Meta+Home";
      KrohnkiteShiftLeft = "Meta+F1";
      KrohnkiteShiftDown = "Meta+F2";
      KrohnkiteShiftUp = "Meta+F3";
      KrohnkiteShiftRight = "Meta+F4";
      KrohnkiteShrinkWidth = "Meta+[";
      KrohnkiteGrowHeight = "Meta+F12";
      KrohnkiteShrinkHeight = "Meta+F11";
      KrohnkitegrowWidth = "Meta+]";
      KrohnkiteIncrease = "Meta+I";
      KrohnkiteDecrease = "Meta+U";
      KrohnkiteToggleFloat = "Meta+F";
      KrohnkiteFloatAll = "Meta+O";
      KrohnkiteNextLayout = "Meta+N";
      KrohnkitePreviousLayout = "Meta+P";
      KrohnkiteRotate = "Meta+R";
      KrohnkiteRotatePart = "Meta+Y";
      KrohnkiteSetMaster = "Meta+S";
      KrohnkiteTileLayout = "Meta+T";
      KrohnkiteMonocleLayout = "Meta+M";
      # 显式清除未启用动作，避免保留旧会话的多修饰键绑定。
      KrohnkitetoggleDock = "";
      KrohnkiteRaiseSurfaceCapacity = "";
      KrohnkiteLowerSurfaceCapacity = "";
      KrohnkiteMeta = "";
      KrohnkiteTreeColumnLayout = "";
      KrohnkiteSpreadLayout = "";
      KrohnkiteStairLayout = "";
      KrohnkiteFloatingLayout = "";
      KrohnkiteQuarterLayout = "";
      KrohnkiteStackedLayout = "";
      KrohnkiteBTreeLayout = "";
      KrohnkiteSpiralLayout = "";
      KrohnkiteColumnsLayout = "";
      KrohnkiteCascadeLayout = "";
    };
  };
}

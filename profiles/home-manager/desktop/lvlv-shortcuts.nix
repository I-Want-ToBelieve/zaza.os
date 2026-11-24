{pkgs, ...}: {
  # 保留输入法 Ctrl+Space；Krohnkite 使用 Meta + 单键。
  xdg.configFile."kitty/quick-access-terminal.conf".text = ''
    edge top
    lines 25
    # top 层允许 Fcitx5 候选窗显示在终端上方。
    layer top
    hide_on_focus_loss no
    grab_keyboard no
  '';

  programs.plasma = {
    enable = true;
    hotkeys.commands = {
      launch-vicinae = {
        name = "Launch Vicinae";
        key = "Meta+Space";
        command = "${pkgs.vicinae}/bin/vicinae toggle";
      };
      launch-kitty = {
        name = "Open terminal";
        key = "Meta+Return";
        command = "${pkgs.kitty}/bin/kitty";
      };
      toggle-kitty-quick-access = {
        name = "Toggle quick access terminal";
        key = "Ctrl+T";
        command = "${pkgs.kitty}/bin/kitten quick-access-terminal --detach";
      };
      capture-flameshot = {
        name = "Capture and annotate";
        keys = ["Print" "Meta+Shift+S"];
        command = "${pkgs.flameshot}/bin/flameshot gui";
      };
      toggle-copyq = {
        name = "Clipboard history";
        key = "Meta+V";
        command = "${pkgs.copyq}/bin/copyq toggle";
      };
    };
    shortcuts = {
      # KDE 自带剪贴板仍可从托盘打开，快捷键由 CopyQ 使用。
      klipper.show-klipper-popupmenu = [];
      "KDE Keyboard Layout Switcher" = {
        "Switch to Last-Used Keyboard Layout" = [];
        "Switch to Next Keyboard Layout" = [];
      };
      plasmashell = {
        show-on-mouse-pos = [];
        cycle-panels = [];
      };
      "org.kde.spectacle.desktop" = {
        _launch = [];
        RectangularRegionScreenShot = [];
        FullScreenScreenShot = [];
      };
      "org.kde.dolphin.desktop"._launch = "Meta+E";
      "org.kde.krunner.desktop"._launch = ["Alt+Space" "Alt+F2"];
      ksmserver."Lock Session" = "Meta+L";
      kwin = {
        # 方向键与 Meta+T 交给 Krohnkite；桌面切换仍保留 Ctrl+F1…F4。
        "Window Quick Tile Left" = [];
        "Window Quick Tile Bottom" = [];
        "Window Quick Tile Top" = [];
        "Window Quick Tile Right" = [];
        "Edit Tiles" = [];
        "Switch to Desktop 1" = "Ctrl+F1";
        "Switch to Desktop 2" = "Ctrl+F2";
        "Switch to Desktop 3" = "Ctrl+F3";
        "Switch to Desktop 4" = "Ctrl+F4";
        "Show Desktop" = "Meta+D";
        Overview = "Meta+W";
        "Switch to Previous Desktop" = "Meta+Ctrl+Left";
        "Switch to Next Desktop" = "Meta+Ctrl+Right";
        "Switch One Desktop to the Left" = [];
        "Switch One Desktop to the Right" = [];
      };
    };
  };
}

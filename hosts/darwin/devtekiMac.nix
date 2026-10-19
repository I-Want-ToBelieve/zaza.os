{pkgs, ...}:
# devtekiMac —— 另一台 Apple Silicon Mac。
#
# **刻意与 hosts/darwin/k99-lite-darwin.nix 并列复制，而不是抽共用 profile。**
# 两台 Mac 的 macOS defaults、键位映射、字体是两组独立决定；并排放着，分歧才
# 看得见。理由同 CLAUDE.md 的「Duplication that is deliberate」。
#
# 与 k99-lite-darwin 的差别只有三处：
#   1. 主机名 / 计算机名 / NetBIOSName → devtekiMac
#   2. system.primaryUser → dev
#   3. **不进 darwinSuites.misc**，因而不带 profiles/darwin/apps.nix。
#      那个 profile 里有 homebrew.onActivation.cleanup = "zap"，它会卸载
#      目标机上一切不在清单里的 brew 包 —— 而那份清单是按 k99-lite-darwin
#      的实际安装情况逐项核对出来的，对这台机器完全不适用。
#      这台机器的 brew 清单要等你在它上面跑过 `brew leaves` / `brew list --cask`
#      之后再定；在那之前这里根本不启用 homebrew 模块。
{
  networking.hostName = "devtekiMac";
  networking.computerName = "devtekiMac";
  system = {
    primaryUser = "dev";

    defaults = {
      smb.NetBIOSName = "devtekiMac";
      menuExtraClock.Show24Hour = true; # show 24 hour clock

      # customize dock
      dock = {
        autohide = false;
        show-recents = false; # disable recent apps

        # customize Hot Corners(触发角, 鼠标移动到屏幕角落时触发的动作)
        wvous-tl-corner = 1; # top-left - disable
        wvous-tr-corner = 1; # top-right - disable
        wvous-bl-corner = 1; # bottom-left - disable
        wvous-br-corner = 1; # bottom-right - disable
      };

      # customize finder
      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        AppleShowAllExtensions = true; # show all file extensions
        FXEnableExtensionChangeWarning = false; # disable warning when changing file extension
        QuitMenuItem = true; # enable quit menu item
        ShowPathbar = true; # show path bar
        ShowStatusBar = true; # show status bar
      };

      # customize trackpad
      trackpad = {
        # tap - 轻触触摸板, click - 点击触摸板
        Clicking = true; # enable tap to click(轻触触摸板相当于点击)
        TrackpadRightClick = true; # enable two finger right click
        TrackpadThreeFingerDrag = true; # enable three finger drag
      };

      # customize macOS
      NSGlobalDomain = {
        # `defaults read NSGlobalDomain "xxx"`
        "com.apple.swipescrolldirection" = false; # enable natural scrolling(default to true)
        "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key
        "com.apple.keyboard.fnState" = true;
        AppleInterfaceStyle = "Dark"; # dark mode
        AppleKeyboardUIMode = 3; # Mode 3 enables full keyboard control.
        ApplePressAndHoldEnabled = true; # enable press and hold
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Automatic";

        # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        # This is very useful for vim users, they use `hjkl` to move cursor.
        # sets how long it takes before it starts repeating.
        InitialKeyRepeat = 15; # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        # sets how fast it repeats once it starts.
        KeyRepeat = 3; # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)

        NSAutomaticCapitalizationEnabled = false; # disable auto capitalization(自动大写)
        NSAutomaticDashSubstitutionEnabled = false; # disable auto dash substitution(智能破折号替换)
        NSAutomaticPeriodSubstitutionEnabled = false; # disable auto period substitution(智能句号替换)
        NSAutomaticQuoteSubstitutionEnabled = false; # disable auto quote substitution(智能引号替换)
        NSAutomaticSpellingCorrectionEnabled = false; # disable auto spelling correction(自动拼写检查)
        NSNavPanelExpandedStateForSaveMode = true; # expand save panel by default(保存文件时的路径选择/文件名输入页)
        NSNavPanelExpandedStateForSaveMode2 = true;
      };

      # Customize settings that not supported by nix-darwin directly
      # see the source code of this project to get more undocumented options:
      #    https://githubfast.com/rgcr/m-cli
      #
      # All custom entries can be found by running `defaults read` command.
      # or `defaults read xxx` to read a specific domain.
      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
        };
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          # When performing a search, search the current folder by default
          FXDefaultSearchScope = "SCcf";
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
      };

      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = false; # show full name in login window
      };
    };

    # keyboard settings is not very useful on macOS
    # the most important thing is to remap option key to alt key globally,
    # but it's not supported by macOS yet.
    keyboard = {
      enableKeyMapping = true; # enable key mapping so that we can use `option` as `control`

      # NOTE: do NOT support remap capslock to both control and escape at the same time
      remapCapsLockToControl = false; # remap caps lock to control, useful for emac users
      remapCapsLockToEscape = true; # remap caps lock to escape, useful for vim users

      # swap left command and left alt
      # so it matches common keyboard layout: `ctrl | command | alt`
      #
      # disabled, caused only problems!
      swapLeftCommandAndLeftAlt = false;
      #  <https://developer.apple.com/library/content/technotes/tn2450/_index.html>.
      #  <https://hidutil-generator.netlify.app/>
      # 16 -> 10 https://codepen.io/floatingshuyin-the-bashful/pen/vYbgJzJ.
      # swapLeftCommandAndLeftCtrl
      userKeyMapping = [
        {
          HIDKeyboardModifierMappingSrc = 30064771296;
          HIDKeyboardModifierMappingDst = 30064771299;
        }
        {
          HIDKeyboardModifierMappingSrc = 30064771299;
          HIDKeyboardModifierMappingDst = 30064771296;
        }
      ];
    };
  };

  # Add ability to used TouchID for sudo authentication
  # security.pam.enableSudoTouchIdAuth = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # apps.nix 没进来（这台机器用 darwinSuites.base），所以最小系统包、
  # EDITOR 和登录 shell 都在这里自己声明。
  environment = {
    systemPackages = with pkgs; [
      neovim
      git
    ];

    variables = {
      # nvim，不是 neovim —— 包名叫 neovim，可执行文件叫 nvim。
      EDITOR = "nvim";

      # Homebrew 的国内镜像。这几项原本由 profiles/darwin/apps.nix 提供，
      # 而这台机器走 darwinSuites.base、不含那个 profile，所以在这里自带。
      HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
      HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
      HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
      HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
      HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
    };

    shells = [pkgs.fish];
  };

  # ── homebrew ──────────────────────────────────────────────────────────
  # nix-darwin 的 homebrew 模块**不负责安装 Homebrew 本身**，它只生成并执行
  # 一个 Brewfile。所以这台机器上要先手工装好 brew（https://brew.sh）。
  #
  # cleanup 是 "none" 而不是 k99-lite-darwin 用的 "zap"，这一点是刻意的：
  # zap 会卸载目标机上一切不在下面清单里的 brew 包，而 homebrew **不在**
  # nix-darwin 的 generation 回滚范围内 —— 卸掉就是卸掉了。
  #
  # 要切到 zap，先在这台机器上把清单补全，判据是：
  #   brew leaves              → 补进 brews（传递依赖不必列，
  #                              brew bundle cleanup 会保留被声明包依赖的那些）
  #   brew list --cask         → 补进 casks
  # 然后确认 `brew bundle cleanup --dry-run` 不会删掉任何你要的东西。
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "none";
    };

    taps = [];

    # 待填 —— 见上面的判据。空列表配 cleanup = "none" 意味着 homebrew 受管
    # 但既不新增也不删除，这是一个安全的起点。
    brews = [];
    casks = [];
  };

  # Set your time zone.
  # comment this due to the issue:
  #   https://githubfast.com/LnL7/nix-darwin/issues/359
  time.timeZone = "Asia/Shanghai";

  # Fonts
  fonts = {
    # use fonts specified by user rather than default ones

    packages = with pkgs; [
      # icon fonts
      material-design-icons
      font-awesome

      # nerdfonts
    ];
  };
}

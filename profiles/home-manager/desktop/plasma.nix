# nix run github:pjones/plasma-manager | xclip -selection c
{
  programs.plasma = {
    enable = true;
    shortcuts = {
      "ActivityManager"."switch-to-activity-2fceeaf5-e7eb-41ea-9108-13788b24131a" =
        [ ];
      "KDE Keyboard Layout Switcher"."Switch keyboard layout to English (US)" =
        [ ];
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" =
        "Meta+Alt+K";
      "bismuth"."decrease_master_size" = [ ];
      "bismuth"."decrease_master_win_count" = [ ];
      "bismuth"."decrease_window_height" = [ ];
      "bismuth"."decrease_window_width" = "Meta+J";
      "bismuth"."focus_bottom_window" = [ ];
      "bismuth"."focus_left_window" = [ ];
      "bismuth"."focus_next_window" = "Meta+K";
      "bismuth"."focus_prev_window" = "Meta+I";
      "bismuth"."focus_right_window" = [ ];
      "bismuth"."focus_upper_window" = [ ];
      "bismuth"."increase_master_size" = [ ];
      "bismuth"."increase_master_win_count" = [ ];
      "bismuth"."increase_window_height" = [ ];
      "bismuth"."increase_window_width" = "Meta+L";
      "bismuth"."move_window_to_bottom_pos" = [ ];
      "bismuth"."move_window_to_left_pos" = [ ];
      "bismuth"."move_window_to_next_pos" = "Meta+Shift+K";
      "bismuth"."move_window_to_prev_pos" = "Meta+Shift+I";
      "bismuth"."move_window_to_right_pos" = [ ];
      "bismuth"."move_window_to_upper_pos" = [ ];
      "bismuth"."next_layout" = "Meta+\\,Meta+\\,Switch to the Next Layout";
      "bismuth"."prev_layout" = "Meta+|";
      "bismuth"."push_window_to_master" = "Meta+Shift+M";
      "bismuth"."rotate" = [ ];
      "bismuth"."rotate_part" = [ ];
      "bismuth"."rotate_reverse" = [ ];
      "bismuth"."toggle_float_layout" = "Meta+F";
      "bismuth"."toggle_monocle_layout" = "Meta+M";
      "bismuth"."toggle_quarter_layout" = [ ];
      "bismuth"."toggle_spiral_layout" = [ ];
      "bismuth"."toggle_spread_layout" = [ ];
      "bismuth"."toggle_stair_layout" = [ ];
      "bismuth"."toggle_three_column_layout" = [ ];
      "bismuth"."toggle_tile_layout" = "Meta+T";
      "bismuth"."toggle_window_floating" = [ ];
      "ddcutil.desktop"."_launch" = "Ctrl+Alt+Shift+M";
      "kaccess"."Toggle Screen Reader On and Off" = "Meta+Alt+S";
      "kcm_touchpad"."Disable Touchpad" = "Touchpad Off";
      "kcm_touchpad"."Enable Touchpad" = "Touchpad On";
      "kcm_touchpad"."Toggle Touchpad" = "Touchpad Toggle";
      "kded5"."Show System Activity" = "Ctrl+Esc";
      "kded5"."display" = [ "Display" "Meta+P" ];
      "khotkeys"."{d03619b6-9b3c-48cc-9d9c-a2aadb485550}" = [ ];
      "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
      "kmix"."decrease_volume" = "Volume Down";
      "kmix"."increase_microphone_volume" = "Microphone Volume Up";
      "kmix"."increase_volume" = "Volume Up";
      "kmix"."mic_mute" = [ "Microphone Mute" "Meta+Volume Mute" ];
      "kmix"."mute" = "Volume Mute";
      "ksmserver"."Halt Without Confirmation" = [ ];
      "ksmserver"."Lock Session" = "Screensaver";
      "ksmserver"."Log Out" = "Ctrl+Alt+Del";
      "ksmserver"."Log Out Without Confirmation" = [ ];
      "ksmserver"."Reboot Without Confirmation" = [ ];
      "kwin"."Activate Window Demanding Attention" = "Meta+Ctrl+A";
      "kwin"."Decrease Opacity" = [ ];
      "kwin"."Edit Tiles" = [ ];
      "kwin"."Expose" = "Ctrl+F9";
      "kwin"."ExposeAll" = [ "Ctrl+F10" "Launch (C)" ];
      "kwin"."ExposeClass" = "Ctrl+F7";
      "kwin"."ExposeClassCurrentDesktop" = [ ];
      "kwin"."Increase Opacity" = [ ];
      "kwin"."Kill Window" = "Meta+Ctrl+Esc";
      "kwin"."Move Tablet to Next Output" = [ ];
      "kwin"."MoveMouseToCenter" = "Meta+F6";
      "kwin"."MoveMouseToFocus" = "Meta+F5";
      "kwin"."MoveZoomDown" = [ ];
      "kwin"."MoveZoomLeft" = [ ];
      "kwin"."MoveZoomRight" = [ ];
      "kwin"."MoveZoomUp" = [ ];
      "kwin"."Overview" = "Meta+W";
      "kwin"."PoloniumFocusAbove" = [ ];
      "kwin"."PoloniumFocusBelow" = [ ];
      "kwin"."PoloniumFocusLeft" = "Meta+H";
      "kwin"."PoloniumFocusRight" = [ ];
      "kwin"."PoloniumInsertAbove" = [ ];
      "kwin"."PoloniumInsertBelow" = [ ];
      "kwin"."PoloniumInsertLeft" = "Meta+Shift+H";
      "kwin"."PoloniumInsertRight" = [ ];
      "kwin"."PoloniumRetileWindow" = "Meta+Shift+Space";
      "kwin"."PoloniumSwapAbove" = "Meta+Ctrl+K";
      "kwin"."PoloniumSwapBelow" = "Meta+Ctrl+J";
      "kwin"."PoloniumSwapLeft" = "Meta+Ctrl+H";
      "kwin"."PoloniumSwapRight" = "Meta+Ctrl+L";
      "kwin"."Setup Window Shortcut" = [ ];
      "kwin"."Show Desktop" = "Meta+D";
      "kwin"."ShowDesktopGrid" = "Meta+F8";
      "kwin"."Suspend Compositing" = "Alt+Shift+F12";
      "kwin"."Switch One Desktop Down" = [ ];
      "kwin"."Switch One Desktop Up" = [ ];
      "kwin"."Switch One Desktop to the Left" = [ ];
      "kwin"."Switch One Desktop to the Right" = [ ];
      "kwin"."Switch Window Down" = "Meta+Alt+Down";
      "kwin"."Switch Window Left" = "Meta+Alt+Left";
      "kwin"."Switch Window Right" = "Meta+Alt+Right";
      "kwin"."Switch Window Up" = "Meta+Alt+Up";
      "kwin"."Switch to Desktop 1" = "Meta+1";
      "kwin"."Switch to Desktop 10" = "Meta+0";
      "kwin"."Switch to Desktop 11" = [ ];
      "kwin"."Switch to Desktop 12" = [ ];
      "kwin"."Switch to Desktop 13" = [ ];
      "kwin"."Switch to Desktop 14" = [ ];
      "kwin"."Switch to Desktop 15" = [ ];
      "kwin"."Switch to Desktop 16" = [ ];
      "kwin"."Switch to Desktop 17" = [ ];
      "kwin"."Switch to Desktop 18" = [ ];
      "kwin"."Switch to Desktop 19" = [ ];
      "kwin"."Switch to Desktop 2" = "Meta+2";
      "kwin"."Switch to Desktop 20" = [ ];
      "kwin"."Switch to Desktop 3" = "Meta+3";
      "kwin"."Switch to Desktop 4" = "Meta+4";
      "kwin"."Switch to Desktop 5" = "Meta+5";
      "kwin"."Switch to Desktop 6" = "Meta+6";
      "kwin"."Switch to Desktop 7" = "Meta+7";
      "kwin"."Switch to Desktop 8" = "Meta+8";
      "kwin"."Switch to Desktop 9" = "Meta+9";
      "kwin"."Switch to Next Desktop" = [ ];
      "kwin"."Switch to Next Screen" = [ ];
      "kwin"."Switch to Previous Desktop" = [ ];
      "kwin"."Switch to Previous Screen" = [ ];
      "kwin"."Switch to Screen 0" = [ ];
      "kwin"."Switch to Screen 1" = [ ];
      "kwin"."Switch to Screen 2" = [ ];
      "kwin"."Switch to Screen 3" = [ ];
      "kwin"."Switch to Screen 4" = [ ];
      "kwin"."Switch to Screen 5" = [ ];
      "kwin"."Switch to Screen 6" = [ ];
      "kwin"."Switch to Screen 7" = [ ];
      "kwin"."Switch to Screen Above" = [ ];
      "kwin"."Switch to Screen Below" = [ ];
      "kwin"."Switch to Screen to the Left" = [ ];
      "kwin"."Switch to Screen to the Right" = [ ];
      "kwin"."Toggle Night Color" = [ ];
      "kwin"."Toggle Window Raise/Lower" = [ ];
      "kwin"."Walk Through Desktop List" = [ ];
      "kwin"."Walk Through Desktop List (Reverse)" = [ ];
      "kwin"."Walk Through Desktops" = [ ];
      "kwin"."Walk Through Desktops (Reverse)" = [ ];
      "kwin"."Walk Through Windows" = "Alt+Tab";
      "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Backtab";
      "kwin"."Walk Through Windows Alternative" = [ ];
      "kwin"."Walk Through Windows Alternative (Reverse)" = [ ];
      "kwin"."Walk Through Windows of Current Application" = "Alt+`";
      "kwin"."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
      "kwin"."Walk Through Windows of Current Application Alternative" = [ ];
      "kwin"."Walk Through Windows of Current Application Alternative (Reverse)" =
        [ ];
      "kwin"."Window Above Other Windows" = [ ];
      "kwin"."Window Below Other Windows" = [ ];
      "kwin"."Window Close" = "Meta+Q";
      "kwin"."Window Fullscreen" = "Meta+Shift+F";
      "kwin"."Window Grow Horizontal" = [ ];
      "kwin"."Window Grow Vertical" = [ ];
      "kwin"."Window Lower" = [ ];
      "kwin"."Window Maximize" = "Meta+PgUp";
      "kwin"."Window Maximize Horizontal" = [ ];
      "kwin"."Window Maximize Vertical" = [ ];
      "kwin"."Window Minimize" = "Meta+X";
      "kwin"."Window Move" = [ ];
      "kwin"."Window Move Center" = [ ];
      "kwin"."Window No Border" = [ ];
      "kwin"."Window On All Desktops" = [ ];
      "kwin"."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
      "kwin"."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
      "kwin"."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
      "kwin"."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
      "kwin"."Window One Screen Down" = [ ];
      "kwin"."Window One Screen Up" = [ ];
      "kwin"."Window One Screen to the Left" = [ ];
      "kwin"."Window One Screen to the Right" = [ ];
      "kwin"."Window Operations Menu" = "Alt+F3";
      "kwin"."Window Pack Down" = [ ];
      "kwin"."Window Pack Left" = [ ];
      "kwin"."Window Pack Right" = [ ];
      "kwin"."Window Pack Up" = [ ];
      "kwin"."Window Quick Tile Bottom" = "Meta+Down";
      "kwin"."Window Quick Tile Bottom Left" = [ ];
      "kwin"."Window Quick Tile Bottom Right" = [ ];
      "kwin"."Window Quick Tile Left" = "Meta+Left";
      "kwin"."Window Quick Tile Right" = "Meta+Right";
      "kwin"."Window Quick Tile Top" = "Meta+Up";
      "kwin"."Window Quick Tile Top Left" = [ ];
      "kwin"."Window Quick Tile Top Right" = [ ];
      "kwin"."Window Raise" = [ ];
      "kwin"."Window Resize" = [ ];
      "kwin"."Window Shade" = [ ];
      "kwin"."Window Shrink Horizontal" = [ ];
      "kwin"."Window Shrink Vertical" = [ ];
      "kwin"."Window to Desktop 1" = "Meta+!";
      "kwin"."Window to Desktop 10" = "Meta+)";
      "kwin"."Window to Desktop 11" = [ ];
      "kwin"."Window to Desktop 12" = [ ];
      "kwin"."Window to Desktop 13" = [ ];
      "kwin"."Window to Desktop 14" = [ ];
      "kwin"."Window to Desktop 15" = [ ];
      "kwin"."Window to Desktop 16" = [ ];
      "kwin"."Window to Desktop 17" = [ ];
      "kwin"."Window to Desktop 18" = [ ];
      "kwin"."Window to Desktop 19" = [ ];
      "kwin"."Window to Desktop 2" = "Meta+@";
      "kwin"."Window to Desktop 20" = [ ];
      "kwin"."Window to Desktop 3" = "Meta+#";
      "kwin"."Window to Desktop 4" = "Meta+$";
      "kwin"."Window to Desktop 5" = "Meta+%";
      "kwin"."Window to Desktop 6" = "Meta+^";
      "kwin"."Window to Desktop 7" = "Meta+&";
      "kwin"."Window to Desktop 8" = "Meta+*";
      "kwin"."Window to Desktop 9" = "Meta+(";
      "kwin"."Window to Next Desktop" = "Meta+Shift+L";
      "kwin"."Window to Next Screen" = [ "Meta+>" "Meta+Shift+Right" ];
      "kwin"."Window to Previous Desktop" = "Meta+Shift+J";
      "kwin"."Window to Previous Screen" = [ "Meta+Shift+Left" "Meta+<" ];
      "kwin"."Window to Screen 0" = [ ];
      "kwin"."Window to Screen 1" = [ ];
      "kwin"."Window to Screen 2" = [ ];
      "kwin"."Window to Screen 3" = [ ];
      "kwin"."Window to Screen 4" = [ ];
      "kwin"."Window to Screen 5" = [ ];
      "kwin"."Window to Screen 6" = [ ];
      "kwin"."Window to Screen 7" = [ ];
      "kwin"."karousel-column-expand" = [ ];
      "kwin"."karousel-column-move-end" = "Meta+Ctrl+Shift+End";
      "kwin"."karousel-column-move-left" = "Meta+Ctrl+Shift+A";
      "kwin"."karousel-column-move-right" = "Meta+Ctrl+Shift+D";
      "kwin"."karousel-column-move-start" = "Meta+Ctrl+Shift+Home";
      "kwin"."karousel-column-move-to-column-1" = "Meta+Ctrl+Shift+1";
      "kwin"."karousel-column-move-to-column-2" = "Meta+Ctrl+Shift+2";
      "kwin"."karousel-column-move-to-column-3" = "Meta+Ctrl+Shift+3";
      "kwin"."karousel-column-move-to-column-4" = "Meta+Ctrl+Shift+4";
      "kwin"."karousel-column-move-to-column-5" = "Meta+Ctrl+Shift+5";
      "kwin"."karousel-column-move-to-column-6" = "Meta+Ctrl+Shift+6";
      "kwin"."karousel-column-move-to-column-7" = "Meta+Ctrl+Shift+7";
      "kwin"."karousel-column-move-to-column-8" = "Meta+Ctrl+Shift+8";
      "kwin"."karousel-column-move-to-column-9" = "Meta+Ctrl+Shift+9";
      "kwin"."karousel-column-move-to-desktop-1" = "Meta+Ctrl+Shift+F1";
      "kwin"."karousel-column-move-to-desktop-10" = "Meta+Ctrl+Shift+F10";
      "kwin"."karousel-column-move-to-desktop-11" = "Meta+Ctrl+Shift+F11";
      "kwin"."karousel-column-move-to-desktop-12" = "Meta+Ctrl+Shift+F12";
      "kwin"."karousel-column-move-to-desktop-2" = "Meta+Ctrl+Shift+F2";
      "kwin"."karousel-column-move-to-desktop-3" = "Meta+Ctrl+Shift+F3";
      "kwin"."karousel-column-move-to-desktop-4" = "Meta+Ctrl+Shift+F4";
      "kwin"."karousel-column-move-to-desktop-5" = "Meta+Ctrl+Shift+F5";
      "kwin"."karousel-column-move-to-desktop-6" = "Meta+Ctrl+Shift+F6";
      "kwin"."karousel-column-move-to-desktop-7" = "Meta+Ctrl+Shift+F7";
      "kwin"."karousel-column-move-to-desktop-8" = "Meta+Ctrl+Shift+F8";
      "kwin"."karousel-column-move-to-desktop-9" = "Meta+Ctrl+Shift+F9";
      "kwin"."karousel-focus-1" = [ ];
      "kwin"."karousel-focus-2" = [ ];
      "kwin"."karousel-focus-3" = [ ];
      "kwin"."karousel-focus-4" = [ ];
      "kwin"."karousel-focus-5" = [ ];
      "kwin"."karousel-focus-6" = [ ];
      "kwin"."karousel-focus-7" = [ ];
      "kwin"."karousel-focus-8" = [ ];
      "kwin"."karousel-focus-9" = [ ];
      "kwin"."karousel-focus-down" = "Meta+S";
      "kwin"."karousel-focus-end" = "Meta+End";
      "kwin"."karousel-focus-left" = [ ];
      "kwin"."karousel-focus-right" = [ ];
      "kwin"."karousel-focus-start" = "Meta+Home";
      "kwin"."karousel-focus-up" = [ ];
      "kwin"."karousel-grid-scroll-end" = "Meta+Alt+End";
      "kwin"."karousel-grid-scroll-focused" = "Meta+Alt+Return";
      "kwin"."karousel-grid-scroll-left" = "Meta+Alt+PgUp";
      "kwin"."karousel-grid-scroll-left-column" = "Meta+Alt+A";
      "kwin"."karousel-grid-scroll-right" = "Meta+Alt+PgDown";
      "kwin"."karousel-grid-scroll-right-column" = "Meta+Alt+D";
      "kwin"."karousel-grid-scroll-start" = "Meta+Alt+Home";
      "kwin"."karousel-tail-move-to-desktop-1" = "Meta+Ctrl+Alt+Shift+F1";
      "kwin"."karousel-tail-move-to-desktop-10" = "Meta+Ctrl+Alt+Shift+F10";
      "kwin"."karousel-tail-move-to-desktop-11" = "Meta+Ctrl+Alt+Shift+F11";
      "kwin"."karousel-tail-move-to-desktop-12" = "Meta+Ctrl+Alt+Shift+F12";
      "kwin"."karousel-tail-move-to-desktop-2" = "Meta+Ctrl+Alt+Shift+F2";
      "kwin"."karousel-tail-move-to-desktop-3" = "Meta+Ctrl+Alt+Shift+F3";
      "kwin"."karousel-tail-move-to-desktop-4" = "Meta+Ctrl+Alt+Shift+F4";
      "kwin"."karousel-tail-move-to-desktop-5" = "Meta+Ctrl+Alt+Shift+F5";
      "kwin"."karousel-tail-move-to-desktop-6" = "Meta+Ctrl+Alt+Shift+F6";
      "kwin"."karousel-tail-move-to-desktop-7" = "Meta+Ctrl+Alt+Shift+F7";
      "kwin"."karousel-tail-move-to-desktop-8" = "Meta+Ctrl+Alt+Shift+F8";
      "kwin"."karousel-tail-move-to-desktop-9" = "Meta+Ctrl+Alt+Shift+F9";
      "kwin"."karousel-window-expand" = [ ];
      "kwin"."karousel-window-move-down" = "Meta+Shift+S";
      "kwin"."karousel-window-move-end" = "Meta+Shift+End";
      "kwin"."karousel-window-move-left" = [ ];
      "kwin"."karousel-window-move-right" = [ ];
      "kwin"."karousel-window-move-start" = "Meta+Shift+Home";
      "kwin"."karousel-window-move-to-column-1" = "Meta+Shift+1";
      "kwin"."karousel-window-move-to-column-2" = "Meta+Shift+2";
      "kwin"."karousel-window-move-to-column-3" = "Meta+Shift+3";
      "kwin"."karousel-window-move-to-column-4" = "Meta+Shift+4";
      "kwin"."karousel-window-move-to-column-5" = "Meta+Shift+5";
      "kwin"."karousel-window-move-to-column-6" = "Meta+Shift+6";
      "kwin"."karousel-window-move-to-column-7" = "Meta+Shift+7";
      "kwin"."karousel-window-move-to-column-8" = "Meta+Shift+8";
      "kwin"."karousel-window-move-to-column-9" = "Meta+Shift+9";
      "kwin"."karousel-window-move-up" = "Meta+Shift+W";
      "kwin"."karousel-window-toggle-floating" = [ ];
      "kwin"."view_actual_size" = [ ];
      "kwin"."view_zoom_in" = [ "Meta++" "Meta+=" ];
      "kwin"."view_zoom_out" = "Meta+-";
      "mediacontrol"."mediavolumedown" = [ ];
      "mediacontrol"."mediavolumeup" = [ ];
      "mediacontrol"."nextmedia" = "Media Next";
      "mediacontrol"."pausemedia" = "Media Pause";
      "mediacontrol"."playmedia" = [ ];
      "mediacontrol"."playpausemedia" = "Media Play";
      "mediacontrol"."previousmedia" = "Media Previous";
      "mediacontrol"."stopmedia" = "Media Stop";
      "org.kde.dolphin.desktop"."_launch" = "Meta+E";
      "org.kde.konsole.desktop"."NewTab" = [ ];
      "org.kde.konsole.desktop"."NewWindow" = [ ];
      "org.kde.konsole.desktop"."_launch" = "Ctrl+Alt+T";
      "org.kde.krunner.desktop"."RunClipboard" = "Alt+Shift+F2";
      "org.kde.krunner.desktop"."_launch" = [ "Alt+Space" "Alt+F2" "Search" ];
      "org.kde.plasma.emojier.desktop"."_launch" = "Meta+.";
      "org.kde.spectacle.desktop"."ActiveWindowScreenShot" = "Meta+Print";
      "org.kde.spectacle.desktop"."CurrentMonitorScreenShot" = [ ];
      "org.kde.spectacle.desktop"."FullScreenScreenShot" = "Shift+Print";
      "org.kde.spectacle.desktop"."OpenWithoutScreenshot" = [ ];
      "org.kde.spectacle.desktop"."RectangularRegionScreenShot" =
        "Meta+Shift+Print";
      "org.kde.spectacle.desktop"."WindowUnderCursorScreenShot" =
        "Meta+Ctrl+Print";
      "org.kde.spectacle.desktop"."_launch" = "Print";
      "org_kde_powerdevil"."Decrease Keyboard Brightness" =
        "Keyboard Brightness Down";
      "org_kde_powerdevil"."Decrease Screen Brightness" =
        "Monitor Brightness Down";
      "org_kde_powerdevil"."Hibernate" = "Hibernate";
      "org_kde_powerdevil"."Increase Keyboard Brightness" =
        "Keyboard Brightness Up";
      "org_kde_powerdevil"."Increase Screen Brightness" =
        "Monitor Brightness Up";
      "org_kde_powerdevil"."PowerDown" = "Power Down";
      "org_kde_powerdevil"."PowerOff" = "Power Off";
      "org_kde_powerdevil"."Sleep" = "Sleep";
      "org_kde_powerdevil"."Toggle Keyboard Backlight" =
        "Keyboard Light On/Off";
      "org_kde_powerdevil"."Turn Off Screen" = [ ];
      "plasmashell"."activate task manager entry 1" = [ ];
      "plasmashell"."activate task manager entry 10" = [ ];
      "plasmashell"."activate task manager entry 2" = [ ];
      "plasmashell"."activate task manager entry 3" = [ ];
      "plasmashell"."activate task manager entry 4" = [ ];
      "plasmashell"."activate task manager entry 5" = [ ];
      "plasmashell"."activate task manager entry 6" = [ ];
      "plasmashell"."activate task manager entry 7" = [ ];
      "plasmashell"."activate task manager entry 8" = [ ];
      "plasmashell"."activate task manager entry 9" = [ ];
      "plasmashell"."clear-history" = [ ];
      "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
      "plasmashell"."cycle-panels" = "Meta+Alt+P";
      "plasmashell"."cycleNextAction" = [ ];
      "plasmashell"."cyclePrevAction" = [ ];
      "plasmashell"."edit_clipboard" = [ ];
      "plasmashell"."manage activities" = [ ];
      "plasmashell"."next activity" = "Meta+Tab";
      "plasmashell"."previous activity" = "Meta+Shift+Tab";
      "plasmashell"."repeat_action" = "Meta+Ctrl+R";
      "plasmashell"."show dashboard" = "Ctrl+F12";
      "plasmashell"."show-barcode" = [ ];
      "plasmashell"."show-on-mouse-pos" = "Meta+V";
      "plasmashell"."stop current activity" = [ ];
      "plasmashell"."switch to next activity" = [ ];
      "plasmashell"."switch to previous activity" = [ ];
      "plasmashell"."toggle do not disturb" = [ ];
      "systemsettings.desktop"."_launch" = "Tools";
      "systemsettings.desktop"."kcm-kscreen" = [ ];
      "systemsettings.desktop"."kcm-lookandfeel" = [ ];
      "systemsettings.desktop"."kcm-users" = [ ];
      "systemsettings.desktop"."powerdevilprofilesconfig" = [ ];
      "systemsettings.desktop"."screenlocker" = [ ];
    };
    configFile = {
      "baloofilerc"."General"."dbVersion" = 2;
      "baloofilerc"."General"."exclude filters" =
        "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,core-dumps,lost+found";
      "baloofilerc"."General"."exclude filters version" = 8;
      "dolphinrc"."CompactMode"."PreviewSize" = 80;
      "dolphinrc"."DetailsMode"."PreviewSize" = 32;
      "dolphinrc"."General.$i"."Version[$i]" = 202;
      "dolphinrc"."General.$i"."ViewPropsTimestamp[$i]" =
        "2023,3,21,20,12,27.81";
      "dolphinrc"."IconsMode"."PreviewSize" = 32;
      "dolphinrc"."KFileDialog Settings"."Places Icons Auto-resize" = false;
      "dolphinrc"."KFileDialog Settings"."Places Icons Static Size" = 16;
      "dolphinrc"."PlacesPanel"."IconSize" = 16;
      "dolphinrc"."Search"."Location" = "Everywhere";
      "kactivitymanagerdrc"."activities"."2fceeaf5-e7eb-41ea-9108-13788b24131a" =
        "Default";
      "kactivitymanagerdrc"."main"."currentActivity" =
        "2fceeaf5-e7eb-41ea-9108-13788b24131a";
      "kcminputrc"."Libinput.1133.16500.Logitech G304"."PointerAccelerationProfile" =
        1;
      "kcminputrc"."Libinput.1133.16519.Logitech G903 LS"."PointerAccelerationProfile" =
        1;
      "kcminputrc"."Libinput.1241.41619.OBINS OBINS\nAnnePro2 Mouse"."PointerAccelerationProfile" =
        1;
      "kcminputrc"."Libinput.9011.26214.ydotoold virtual device"."PointerAccelerationProfile" =
        1;
      "kcminputrc"."Mouse"."X11LibInputXAccelProfileFlat" = false;
      "kcminputrc"."Mouse"."XLbInptAccelProfileFlat" = true;
      "kcminputrc"."Mouse"."cursorTheme" = "Future-dark-cursors";
      "kded5rc"."Module-appmenu"."autoload" = false;
      "kded5rc"."Module-baloosearchmodule"."autoload" = true;
      "kded5rc"."Module-bluedevil"."autoload" = true;
      "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
      "kded5rc"."Module-colorcorrectlocationupdater"."autoload" = true;
      "kded5rc"."Module-device_automounter"."autoload" = false;
      "kded5rc"."Module-freespacenotifier"."autoload" = true;
      "kded5rc"."Module-gtkconfig"."autoload" = true;
      "kded5rc"."Module-inotify"."autoload" = true;
      "kded5rc"."Module-kded_touchpad"."autoload" = true;
      "kded5rc"."Module-keyboard"."autoload" = true;
      "kded5rc"."Module-khotkeys"."autoload" = true;
      "kded5rc"."Module-kscreen"."autoload" = true;
      "kded5rc"."Module-ksysguard"."autoload" = true;
      "kded5rc"."Module-ktimezoned"."autoload" = true;
      "kded5rc"."Module-networkmanagement"."autoload" = true;
      "kded5rc"."Module-networkstatus"."autoload" = true;
      "kded5rc"."Module-plasma_accentcolor_service"."autoload" = true;
      "kded5rc"."Module-printmanager"."autoload" = true;
      "kded5rc"."Module-proxyscout"."autoload" = true;
      "kded5rc"."Module-remotenotifier"."autoload" = true;
      "kded5rc"."Module-smbwatcher"."autoload" = true;
      "kded5rc"."Module-statusnotifierwatcher"."autoload" = true;
      "kded5rc"."PlasmaBrowserIntegration"."shownCount" = 4;
      "kdeglobals"."DirSelect Dialog"."DirSelectDialog Size" = "1478,1370";
      "kdeglobals"."General"."AllowKDEAppsToRememberWindowPositions" = true;
      "kdeglobals"."General"."BrowserApplication" = "google-chrome.desktop";
      "kdeglobals"."General"."XftHintStyle" = "hintfull";
      "kdeglobals"."General"."XftSubPixel" = "none";
      "kdeglobals"."General"."accentColorFromWallpaper" = false;
      "kdeglobals"."General"."font" = "Noto Sans,10,-1,5,50,0,0,0,0,0";
      "kdeglobals"."KDE"."ScrollbarLeftClickNavigatesByPage" = false;
      "kdeglobals"."KDE"."SingleClick" = true;
      "kdeglobals"."KDE"."widgetStyle" = "kvantum-dark";
      "kdeglobals"."KFileDialog Settings"."Allow Expansion" = false;
      "kdeglobals"."KFileDialog Settings"."Automatically select filename extension" =
        true;
      "kdeglobals"."KFileDialog Settings"."Breadcrumb Navigation" = true;
      "kdeglobals"."KFileDialog Settings"."Decoration position" = 2;
      "kdeglobals"."KFileDialog Settings"."LocationCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."PathCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."Show Bookmarks" = false;
      "kdeglobals"."KFileDialog Settings"."Show Full Path" = false;
      "kdeglobals"."KFileDialog Settings"."Show Inline Previews" = true;
      "kdeglobals"."KFileDialog Settings"."Show Preview" = false;
      "kdeglobals"."KFileDialog Settings"."Show Speedbar" = true;
      "kdeglobals"."KFileDialog Settings"."Show hidden files" = true;
      "kdeglobals"."KFileDialog Settings"."Sort by" = "Name";
      "kdeglobals"."KFileDialog Settings"."Sort directories first" = true;
      "kdeglobals"."KFileDialog Settings"."Sort hidden files last" = false;
      "kdeglobals"."KFileDialog Settings"."Sort reversed" = false;
      "kdeglobals"."KFileDialog Settings"."Speedbar Width" = 138;
      "kdeglobals"."KFileDialog Settings"."View Style" = "DetailTree";
      "kdeglobals"."KScreen"."ScreenScaleFactors" = "DP-4=1;";
      "kdeglobals"."Shortcuts"."Reload" = "Refresh";
      "kdeglobals"."WM"."activeBackground" = "51,51,51";
      "kdeglobals"."WM"."activeBlend" = "171,171,171";
      "kdeglobals"."WM"."activeForeground" = "252,252,252";
      "kdeglobals"."WM"."frame" = "110,255,137";
      "kdeglobals"."WM"."inactiveBackground" = "66,66,66";
      "kdeglobals"."WM"."inactiveBlend" = "85,85,85";
      "kdeglobals"."WM"."inactiveForeground" = "170,170,170";
      "kdeglobals"."WM"."inactiveFrame" = "81,100,104";
      "kgammarc"."ConfigFile"."use" = "kgammarc";
      "kglobalshortcutsrc"."ActivityManager"."_k_friendly_name" =
        "Activity Manager";
      "kglobalshortcutsrc"."KDE Keyboard Layout Switcher"."_k_friendly_name" =
        "Keyboard Layout Switcher";
      "kglobalshortcutsrc"."bismuth"."_k_friendly_name" = "Window Tiling";
      "kglobalshortcutsrc"."ddcutil.desktop"."_k_friendly_name" =
        "ddcutil setvcp 60 11";
      "kglobalshortcutsrc"."kaccess"."_k_friendly_name" = "Accessibility";
      "kglobalshortcutsrc"."kcm_touchpad"."_k_friendly_name" = "Touchpad";
      "kglobalshortcutsrc"."kded5"."_k_friendly_name" = "KDE Daemon";
      "kglobalshortcutsrc"."khotkeys"."_k_friendly_name" =
        "Custom Shortcuts Service";
      "kglobalshortcutsrc"."kmix"."_k_friendly_name" = "Audio Volume";
      "kglobalshortcutsrc"."ksmserver"."_k_friendly_name" =
        "Session Management";
      "kglobalshortcutsrc"."kwin"."_k_friendly_name" = "KWin";
      "kglobalshortcutsrc"."mediacontrol"."_k_friendly_name" =
        "Media Controller";
      "kglobalshortcutsrc"."org.kde.dolphin.desktop"."_k_friendly_name" =
        "Dolphin";
      "kglobalshortcutsrc"."org.kde.konsole.desktop"."_k_friendly_name" =
        "Konsole";
      "kglobalshortcutsrc"."org.kde.krunner.desktop"."_k_friendly_name" =
        "KRunner";
      "kglobalshortcutsrc"."org.kde.plasma.emojier.desktop"."_k_friendly_name" =
        "Emoji Selector";
      "kglobalshortcutsrc"."org.kde.spectacle.desktop"."_k_friendly_name" =
        "Spectacle";
      "kglobalshortcutsrc"."org_kde_powerdevil"."_k_friendly_name" =
        "Power Management";
      "kglobalshortcutsrc"."plasmashell"."_k_friendly_name" = "Plasma";
      "kglobalshortcutsrc"."systemsettings.desktop"."_k_friendly_name" =
        "System Settings";
      "khotkeysrc"."Data"."DataCount" = 3;
      "khotkeysrc"."Data_1"."Comment" = "KMenuEdit Global Shortcuts";
      "khotkeysrc"."Data_1"."DataCount" = 1;
      "khotkeysrc"."Data_1"."Enabled" = true;
      "khotkeysrc"."Data_1"."Name" = "KMenuEdit";
      "khotkeysrc"."Data_1"."SystemGroup" = 1;
      "khotkeysrc"."Data_1"."Type" = "ACTION_DATA_GROUP";
      "khotkeysrc"."Data_1Conditions"."Comment" = "";
      "khotkeysrc"."Data_1Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_1_1"."Comment" = "Comment";
      "khotkeysrc"."Data_1_1"."Enabled" = true;
      "khotkeysrc"."Data_1_1"."Name" = "Search";
      "khotkeysrc"."Data_1_1"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_1_1Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_1_1Actions0"."CommandURL" = "http://google.com";
      "khotkeysrc"."Data_1_1Actions0"."Type" = "COMMAND_URL";
      "khotkeysrc"."Data_1_1Conditions"."Comment" = "";
      "khotkeysrc"."Data_1_1Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_1_1Triggers"."Comment" = "Simple_action";
      "khotkeysrc"."Data_1_1Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_1_1Triggers0"."Key" = "";
      "khotkeysrc"."Data_1_1Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_1_1Triggers0"."Uuid" =
        "{d03619b6-9b3c-48cc-9d9c-a2aadb485550}";
      "khotkeysrc"."Data_2"."Comment" =
        "This group contains various examples demonstrating most of the features of KHotkeys. (Note that this group and all its actions are disabled by default.)";
      "khotkeysrc"."Data_2"."DataCount" = 8;
      "khotkeysrc"."Data_2"."Enabled" = false;
      "khotkeysrc"."Data_2"."ImportId" = "kde32b1";
      "khotkeysrc"."Data_2"."Name" = "Examples";
      "khotkeysrc"."Data_2"."SystemGroup" = 0;
      "khotkeysrc"."Data_2"."Type" = "ACTION_DATA_GROUP";
      "khotkeysrc"."Data_2Conditions"."Comment" = "";
      "khotkeysrc"."Data_2Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_1"."Comment" =
        "After pressing Ctrl+Alt+I, the KSIRC window will be activated, if it exists. Simple.";
      "khotkeysrc"."Data_2_1"."Enabled" = false;
      "khotkeysrc"."Data_2_1"."Name" = "Activate KSIRC Window";
      "khotkeysrc"."Data_2_1"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_1Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_1Actions0"."Type" = "ACTIVATE_WINDOW";
      "khotkeysrc"."Data_2_1Actions0Window"."Comment" = "KSIRC window";
      "khotkeysrc"."Data_2_1Actions0Window"."WindowsCount" = 1;
      "khotkeysrc"."Data_2_1Actions0Window0"."Class" = "ksirc";
      "khotkeysrc"."Data_2_1Actions0Window0"."ClassType" = 1;
      "khotkeysrc"."Data_2_1Actions0Window0"."Comment" = "KSIRC";
      "khotkeysrc"."Data_2_1Actions0Window0"."Role" = "";
      "khotkeysrc"."Data_2_1Actions0Window0"."RoleType" = 0;
      "khotkeysrc"."Data_2_1Actions0Window0"."Title" = "";
      "khotkeysrc"."Data_2_1Actions0Window0"."TitleType" = 0;
      "khotkeysrc"."Data_2_1Actions0Window0"."Type" = "SIMPLE";
      "khotkeysrc"."Data_2_1Actions0Window0"."WindowTypes" = 33;
      "khotkeysrc"."Data_2_1Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_1Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_1Triggers"."Comment" = "Simple_action";
      "khotkeysrc"."Data_2_1Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_2_1Triggers0"."Key" = "Ctrl+Alt+I";
      "khotkeysrc"."Data_2_1Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_2_1Triggers0"."Uuid" =
        "{bfea8022-efd1-4281-ac96-f7a115eb1326}";
      "khotkeysrc"."Data_2_2"."Comment" = ''
        After pressing Alt+Ctrl+H the input of 'Hello' will be simulated, as if you typed it.  This is especially useful if you have call to frequently type a word (for instance, 'unsigned').  Every keypress in the input is separated by a colon ':'. Note that the keypresses literally mean keypresses, so you have to write what you would press on the keyboard. In the table below, the left column shows the input and the right column shows what to type.

        "enter" (i.e. new line)                Enter or Return
        a (i.e. small a)                          A
        A (i.e. capital a)                       Shift+A
        : (colon)                                  Shift+;
        ' '  (space)                              Space'';
      "khotkeysrc"."Data_2_2"."Enabled" = false;
      "khotkeysrc"."Data_2_2"."Name" = "Type 'Hello'";
      "khotkeysrc"."Data_2_2"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_2Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_2Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_2_2Actions0"."Input" = ''
        Shift+H:E:L:L:O
      '';
      "khotkeysrc"."Data_2_2Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_2_2Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_2Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_2Triggers"."Comment" = "Simple_action";
      "khotkeysrc"."Data_2_2Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_2_2Triggers0"."Key" = "Ctrl+Alt+H";
      "khotkeysrc"."Data_2_2Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_2_2Triggers0"."Uuid" =
        "{04c46ebe-3de0-438b-ab18-4ff6d5250b9a}";
      "khotkeysrc"."Data_2_3"."Comment" =
        "This action runs Konsole, after pressing Ctrl+Alt+T.";
      "khotkeysrc"."Data_2_3"."Enabled" = false;
      "khotkeysrc"."Data_2_3"."Name" = "Run Konsole";
      "khotkeysrc"."Data_2_3"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_3Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_3Actions0"."CommandURL" = "konsole";
      "khotkeysrc"."Data_2_3Actions0"."Type" = "COMMAND_URL";
      "khotkeysrc"."Data_2_3Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_3Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_3Triggers"."Comment" = "Simple_action";
      "khotkeysrc"."Data_2_3Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_2_3Triggers0"."Key" = "Ctrl+Alt+T";
      "khotkeysrc"."Data_2_3Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_2_3Triggers0"."Uuid" =
        "{22829a6b-7bc6-45cd-9b16-6401743ffa41}";
      "khotkeysrc"."Data_2_4"."Comment" = ''
        Read the comment on the "Type 'Hello'" action first.

        Qt Designer uses Ctrl+F4 for closing windows.  In KDE, however, Ctrl+F4 is the shortcut for going to virtual desktop 4, so this shortcut does not work in Qt Designer.  Further, Qt Designer does not use KDE's standard Ctrl+W for closing the window.

        This problem can be solved by remapping Ctrl+W to Ctrl+F4 when the active window is Qt Designer. When Qt Designer is active, every time Ctrl+W is pressed, Ctrl+F4 will be sent to Qt Designer instead. In other applications, the effect of Ctrl+W is unchanged.

        We now need to specify three things: A new shortcut trigger on 'Ctrl+W', a new keyboard input action sending Ctrl+F4, and a new condition that the active window is Qt Designer.
        Qt Designer seems to always have title 'Qt Designer by Trolltech', so the condition will check for the active window having that title.'';
      "khotkeysrc"."Data_2_4"."Enabled" = false;
      "khotkeysrc"."Data_2_4"."Name" = "Remap Ctrl+W to Ctrl+F4 in Qt Designer";
      "khotkeysrc"."Data_2_4"."Type" = "GENERIC_ACTION_DATA";
      "khotkeysrc"."Data_2_4Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_4Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_2_4Actions0"."Input" = "Ctrl+F4";
      "khotkeysrc"."Data_2_4Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_2_4Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_4Conditions"."ConditionsCount" = 1;
      "khotkeysrc"."Data_2_4Conditions0"."Type" = "ACTIVE_WINDOW";
      "khotkeysrc"."Data_2_4Conditions0Window"."Comment" = "Qt Designer";
      "khotkeysrc"."Data_2_4Conditions0Window"."WindowsCount" = 1;
      "khotkeysrc"."Data_2_4Conditions0Window0"."Class" = "";
      "khotkeysrc"."Data_2_4Conditions0Window0"."ClassType" = 0;
      "khotkeysrc"."Data_2_4Conditions0Window0"."Comment" = "";
      "khotkeysrc"."Data_2_4Conditions0Window0"."Role" = "";
      "khotkeysrc"."Data_2_4Conditions0Window0"."RoleType" = 0;
      "khotkeysrc"."Data_2_4Conditions0Window0"."Title" =
        "Qt Designer by Trolltech";
      "khotkeysrc"."Data_2_4Conditions0Window0"."TitleType" = 2;
      "khotkeysrc"."Data_2_4Conditions0Window0"."Type" = "SIMPLE";
      "khotkeysrc"."Data_2_4Conditions0Window0"."WindowTypes" = 33;
      "khotkeysrc"."Data_2_4Triggers"."Comment" = "";
      "khotkeysrc"."Data_2_4Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_2_4Triggers0"."Key" = "Ctrl+W";
      "khotkeysrc"."Data_2_4Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_2_4Triggers0"."Uuid" =
        "{7ffc92a7-d1cf-403b-a465-e249efc27591}";
      "khotkeysrc"."Data_2_5"."Comment" =
        "By pressing Alt+Ctrl+W a D-Bus call will be performed that will show the minicli. You can use any kind of D-Bus call, just like using the command line 'qdbus' tool.";
      "khotkeysrc"."Data_2_5"."Enabled" = false;
      "khotkeysrc"."Data_2_5"."Name" =
        "Perform D-Bus call 'qdbus org.kde.krunner /App display'";
      "khotkeysrc"."Data_2_5"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_5Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_5Actions0"."Arguments" = "";
      "khotkeysrc"."Data_2_5Actions0"."Call" = "popupExecuteCommand";
      "khotkeysrc"."Data_2_5Actions0"."RemoteApp" = "org.kde.krunner";
      "khotkeysrc"."Data_2_5Actions0"."RemoteObj" = "/App";
      "khotkeysrc"."Data_2_5Actions0"."Type" = "DBUS";
      "khotkeysrc"."Data_2_5Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_5Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_5Triggers"."Comment" = "Simple_action";
      "khotkeysrc"."Data_2_5Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_2_5Triggers0"."Key" = "Ctrl+Alt+W";
      "khotkeysrc"."Data_2_5Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_2_5Triggers0"."Uuid" =
        "{c055b476-0c9b-47c1-a45e-981a168a2489}";
      "khotkeysrc"."Data_2_6"."Comment" = ''
        Read the comment on the "Type 'Hello'" action first.

        Just like the "Type 'Hello'" action, this one simulates keyboard input, specifically, after pressing Ctrl+Alt+B, it sends B to XMMS (B in XMMS jumps to the next song). The 'Send to specific window' checkbox is checked and a window with its class containing 'XMMS_Player' is specified; this will make the input always be sent to this window. This way, you can control XMMS even if, for instance, it is on a different virtual desktop.

        (Run 'xprop' and click on the XMMS window and search for WM_CLASS to see 'XMMS_Player').'';
      "khotkeysrc"."Data_2_6"."Enabled" = false;
      "khotkeysrc"."Data_2_6"."Name" = "Next in XMMS";
      "khotkeysrc"."Data_2_6"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_6Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_6Actions0"."DestinationWindow" = 1;
      "khotkeysrc"."Data_2_6Actions0"."Input" = "B";
      "khotkeysrc"."Data_2_6Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_2_6Actions0DestinationWindow"."Comment" =
        "XMMS window";
      "khotkeysrc"."Data_2_6Actions0DestinationWindow"."WindowsCount" = 1;
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."Class" = "XMMS_Player";
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."ClassType" = 1;
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."Comment" =
        "XMMS Player window";
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."Role" = "";
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."RoleType" = 0;
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."Title" = "";
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."TitleType" = 0;
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."Type" = "SIMPLE";
      "khotkeysrc"."Data_2_6Actions0DestinationWindow0"."WindowTypes" = 33;
      "khotkeysrc"."Data_2_6Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_6Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_6Triggers"."Comment" = "Simple_action";
      "khotkeysrc"."Data_2_6Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_2_6Triggers0"."Key" = "Ctrl+Alt+B";
      "khotkeysrc"."Data_2_6Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_2_6Triggers0"."Uuid" =
        "{a58fcd9b-18fd-4de6-ba54-ef1904164e5a}";
      "khotkeysrc"."Data_2_7"."Comment" = ''
        Konqueror in KDE3.1 has tabs, and now you can also have gestures.

        Just press the middle mouse button and start drawing one of the gestures, and after you are finished, release the mouse button. If you only need to paste the selection, it still works, just click the middle mouse button. (You can change the mouse button to use in the global settings).

        Right now, there are the following gestures available:
        move right and back left - Forward (Alt+Right)
        move left and back right - Back (Alt+Left)
        move up and back down  - Up (Alt+Up)
        circle counterclockwise - Reload (F5)

        The gesture shapes can be entered by performing them in the configuration dialog. You can also look at your numeric pad to help you: gestures are recognized like a 3x3 grid of fields, numbered 1 to 9.

        Note that you must perform exactly the gesture to trigger the action. Because of this, it is possible to enter more gestures for the action. You should try to avoid complicated gestures where you change the direction of mouse movement more than once.  For instance, 45654 or 74123 are simple to perform, but 1236987 may be already quite difficult.

        The conditions for all gestures are defined in this group. All these gestures are active only if the active window is Konqueror (class contains 'konqueror').'';
      "khotkeysrc"."Data_2_7"."DataCount" = 4;
      "khotkeysrc"."Data_2_7"."Enabled" = false;
      "khotkeysrc"."Data_2_7"."Name" = "Konqi Gestures";
      "khotkeysrc"."Data_2_7"."SystemGroup" = 0;
      "khotkeysrc"."Data_2_7"."Type" = "ACTION_DATA_GROUP";
      "khotkeysrc"."Data_2_7Conditions"."Comment" = "Konqueror window";
      "khotkeysrc"."Data_2_7Conditions"."ConditionsCount" = 1;
      "khotkeysrc"."Data_2_7Conditions0"."Type" = "ACTIVE_WINDOW";
      "khotkeysrc"."Data_2_7Conditions0Window"."Comment" = "Konqueror";
      "khotkeysrc"."Data_2_7Conditions0Window"."WindowsCount" = 1;
      "khotkeysrc"."Data_2_7Conditions0Window0"."Class" = "konqueror";
      "khotkeysrc"."Data_2_7Conditions0Window0"."ClassType" = 1;
      "khotkeysrc"."Data_2_7Conditions0Window0"."Comment" = "Konqueror";
      "khotkeysrc"."Data_2_7Conditions0Window0"."Role" = "";
      "khotkeysrc"."Data_2_7Conditions0Window0"."RoleType" = 0;
      "khotkeysrc"."Data_2_7Conditions0Window0"."Title" = "";
      "khotkeysrc"."Data_2_7Conditions0Window0"."TitleType" = 0;
      "khotkeysrc"."Data_2_7Conditions0Window0"."Type" = "SIMPLE";
      "khotkeysrc"."Data_2_7Conditions0Window0"."WindowTypes" = 33;
      "khotkeysrc"."Data_2_7_1"."Comment" = "";
      "khotkeysrc"."Data_2_7_1"."Enabled" = false;
      "khotkeysrc"."Data_2_7_1"."Name" = "Back";
      "khotkeysrc"."Data_2_7_1"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_7_1Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_7_1Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_2_7_1Actions0"."Input" = "Alt+Left";
      "khotkeysrc"."Data_2_7_1Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_2_7_1Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_7_1Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_7_1Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_2_7_1Triggers"."TriggersCount" = 3;
      "khotkeysrc"."Data_2_7_1Triggers0"."GesturePointData" =
        "0,0.0625,1,1,0.5,0.0625,0.0625,1,0.875,0.5,0.125,0.0625,1,0.75,0.5,0.1875,0.0625,1,0.625,0.5,0.25,0.0625,1,0.5,0.5,0.3125,0.0625,1,0.375,0.5,0.375,0.0625,1,0.25,0.5,0.4375,0.0625,1,0.125,0.5,0.5,0.0625,0,0,0.5,0.5625,0.0625,0,0.125,0.5,0.625,0.0625,0,0.25,0.5,0.6875,0.0625,0,0.375,0.5,0.75,0.0625,0,0.5,0.5,0.8125,0.0625,0,0.625,0.5,0.875,0.0625,0,0.75,0.5,0.9375,0.0625,0,0.875,0.5,1,0,0,1,0.5";
      "khotkeysrc"."Data_2_7_1Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_1Triggers1"."GesturePointData" =
        "0,0.0833333,1,0.5,0.5,0.0833333,0.0833333,1,0.375,0.5,0.166667,0.0833333,1,0.25,0.5,0.25,0.0833333,1,0.125,0.5,0.333333,0.0833333,0,0,0.5,0.416667,0.0833333,0,0.125,0.5,0.5,0.0833333,0,0.25,0.5,0.583333,0.0833333,0,0.375,0.5,0.666667,0.0833333,0,0.5,0.5,0.75,0.0833333,0,0.625,0.5,0.833333,0.0833333,0,0.75,0.5,0.916667,0.0833333,0,0.875,0.5,1,0,0,1,0.5";
      "khotkeysrc"."Data_2_7_1Triggers1"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_1Triggers2"."GesturePointData" =
        "0,0.0833333,1,1,0.5,0.0833333,0.0833333,1,0.875,0.5,0.166667,0.0833333,1,0.75,0.5,0.25,0.0833333,1,0.625,0.5,0.333333,0.0833333,1,0.5,0.5,0.416667,0.0833333,1,0.375,0.5,0.5,0.0833333,1,0.25,0.5,0.583333,0.0833333,1,0.125,0.5,0.666667,0.0833333,0,0,0.5,0.75,0.0833333,0,0.125,0.5,0.833333,0.0833333,0,0.25,0.5,0.916667,0.0833333,0,0.375,0.5,1,0,0,0.5,0.5";
      "khotkeysrc"."Data_2_7_1Triggers2"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_2"."Comment" = "";
      "khotkeysrc"."Data_2_7_2"."Enabled" = false;
      "khotkeysrc"."Data_2_7_2"."Name" = "Forward";
      "khotkeysrc"."Data_2_7_2"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_7_2Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_7_2Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_2_7_2Actions0"."Input" = "Alt+Right";
      "khotkeysrc"."Data_2_7_2Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_2_7_2Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_7_2Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_7_2Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_2_7_2Triggers"."TriggersCount" = 3;
      "khotkeysrc"."Data_2_7_2Triggers0"."GesturePointData" =
        "0,0.0625,0,0,0.5,0.0625,0.0625,0,0.125,0.5,0.125,0.0625,0,0.25,0.5,0.1875,0.0625,0,0.375,0.5,0.25,0.0625,0,0.5,0.5,0.3125,0.0625,0,0.625,0.5,0.375,0.0625,0,0.75,0.5,0.4375,0.0625,0,0.875,0.5,0.5,0.0625,1,1,0.5,0.5625,0.0625,1,0.875,0.5,0.625,0.0625,1,0.75,0.5,0.6875,0.0625,1,0.625,0.5,0.75,0.0625,1,0.5,0.5,0.8125,0.0625,1,0.375,0.5,0.875,0.0625,1,0.25,0.5,0.9375,0.0625,1,0.125,0.5,1,0,0,0,0.5";
      "khotkeysrc"."Data_2_7_2Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_2Triggers1"."GesturePointData" =
        "0,0.0833333,0,0.5,0.5,0.0833333,0.0833333,0,0.625,0.5,0.166667,0.0833333,0,0.75,0.5,0.25,0.0833333,0,0.875,0.5,0.333333,0.0833333,1,1,0.5,0.416667,0.0833333,1,0.875,0.5,0.5,0.0833333,1,0.75,0.5,0.583333,0.0833333,1,0.625,0.5,0.666667,0.0833333,1,0.5,0.5,0.75,0.0833333,1,0.375,0.5,0.833333,0.0833333,1,0.25,0.5,0.916667,0.0833333,1,0.125,0.5,1,0,0,0,0.5";
      "khotkeysrc"."Data_2_7_2Triggers1"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_2Triggers2"."GesturePointData" =
        "0,0.0833333,0,0,0.5,0.0833333,0.0833333,0,0.125,0.5,0.166667,0.0833333,0,0.25,0.5,0.25,0.0833333,0,0.375,0.5,0.333333,0.0833333,0,0.5,0.5,0.416667,0.0833333,0,0.625,0.5,0.5,0.0833333,0,0.75,0.5,0.583333,0.0833333,0,0.875,0.5,0.666667,0.0833333,1,1,0.5,0.75,0.0833333,1,0.875,0.5,0.833333,0.0833333,1,0.75,0.5,0.916667,0.0833333,1,0.625,0.5,1,0,0,0.5,0.5";
      "khotkeysrc"."Data_2_7_2Triggers2"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_3"."Comment" = "";
      "khotkeysrc"."Data_2_7_3"."Enabled" = false;
      "khotkeysrc"."Data_2_7_3"."Name" = "Up";
      "khotkeysrc"."Data_2_7_3"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_7_3Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_7_3Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_2_7_3Actions0"."Input" = "Alt+Up";
      "khotkeysrc"."Data_2_7_3Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_2_7_3Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_7_3Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_7_3Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_2_7_3Triggers"."TriggersCount" = 3;
      "khotkeysrc"."Data_2_7_3Triggers0"."GesturePointData" =
        "0,0.0625,-0.5,0.5,1,0.0625,0.0625,-0.5,0.5,0.875,0.125,0.0625,-0.5,0.5,0.75,0.1875,0.0625,-0.5,0.5,0.625,0.25,0.0625,-0.5,0.5,0.5,0.3125,0.0625,-0.5,0.5,0.375,0.375,0.0625,-0.5,0.5,0.25,0.4375,0.0625,-0.5,0.5,0.125,0.5,0.0625,0.5,0.5,0,0.5625,0.0625,0.5,0.5,0.125,0.625,0.0625,0.5,0.5,0.25,0.6875,0.0625,0.5,0.5,0.375,0.75,0.0625,0.5,0.5,0.5,0.8125,0.0625,0.5,0.5,0.625,0.875,0.0625,0.5,0.5,0.75,0.9375,0.0625,0.5,0.5,0.875,1,0,0,0.5,1";
      "khotkeysrc"."Data_2_7_3Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_3Triggers1"."GesturePointData" =
        "0,0.0833333,-0.5,0.5,1,0.0833333,0.0833333,-0.5,0.5,0.875,0.166667,0.0833333,-0.5,0.5,0.75,0.25,0.0833333,-0.5,0.5,0.625,0.333333,0.0833333,-0.5,0.5,0.5,0.416667,0.0833333,-0.5,0.5,0.375,0.5,0.0833333,-0.5,0.5,0.25,0.583333,0.0833333,-0.5,0.5,0.125,0.666667,0.0833333,0.5,0.5,0,0.75,0.0833333,0.5,0.5,0.125,0.833333,0.0833333,0.5,0.5,0.25,0.916667,0.0833333,0.5,0.5,0.375,1,0,0,0.5,0.5";
      "khotkeysrc"."Data_2_7_3Triggers1"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_3Triggers2"."GesturePointData" =
        "0,0.0833333,-0.5,0.5,0.5,0.0833333,0.0833333,-0.5,0.5,0.375,0.166667,0.0833333,-0.5,0.5,0.25,0.25,0.0833333,-0.5,0.5,0.125,0.333333,0.0833333,0.5,0.5,0,0.416667,0.0833333,0.5,0.5,0.125,0.5,0.0833333,0.5,0.5,0.25,0.583333,0.0833333,0.5,0.5,0.375,0.666667,0.0833333,0.5,0.5,0.5,0.75,0.0833333,0.5,0.5,0.625,0.833333,0.0833333,0.5,0.5,0.75,0.916667,0.0833333,0.5,0.5,0.875,1,0,0,0.5,1";
      "khotkeysrc"."Data_2_7_3Triggers2"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_4"."Comment" = "";
      "khotkeysrc"."Data_2_7_4"."Enabled" = false;
      "khotkeysrc"."Data_2_7_4"."Name" = "Reload";
      "khotkeysrc"."Data_2_7_4"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_7_4Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_7_4Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_2_7_4Actions0"."Input" = "F5";
      "khotkeysrc"."Data_2_7_4Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_2_7_4Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_7_4Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_7_4Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_2_7_4Triggers"."TriggersCount" = 3;
      "khotkeysrc"."Data_2_7_4Triggers0"."GesturePointData" =
        "0,0.03125,0,0,1,0.03125,0.03125,0,0.125,1,0.0625,0.03125,0,0.25,1,0.09375,0.03125,0,0.375,1,0.125,0.03125,0,0.5,1,0.15625,0.03125,0,0.625,1,0.1875,0.03125,0,0.75,1,0.21875,0.03125,0,0.875,1,0.25,0.03125,-0.5,1,1,0.28125,0.03125,-0.5,1,0.875,0.3125,0.03125,-0.5,1,0.75,0.34375,0.03125,-0.5,1,0.625,0.375,0.03125,-0.5,1,0.5,0.40625,0.03125,-0.5,1,0.375,0.4375,0.03125,-0.5,1,0.25,0.46875,0.03125,-0.5,1,0.125,0.5,0.03125,1,1,0,0.53125,0.03125,1,0.875,0,0.5625,0.03125,1,0.75,0,0.59375,0.03125,1,0.625,0,0.625,0.03125,1,0.5,0,0.65625,0.03125,1,0.375,0,0.6875,0.03125,1,0.25,0,0.71875,0.03125,1,0.125,0,0.75,0.03125,0.5,0,0,0.78125,0.03125,0.5,0,0.125,0.8125,0.03125,0.5,0,0.25,0.84375,0.03125,0.5,0,0.375,0.875,0.03125,0.5,0,0.5,0.90625,0.03125,0.5,0,0.625,0.9375,0.03125,0.5,0,0.75,0.96875,0.03125,0.5,0,0.875,1,0,0,0,1";
      "khotkeysrc"."Data_2_7_4Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_4Triggers1"."GesturePointData" =
        "0,0.0277778,0,0,1,0.0277778,0.0277778,0,0.125,1,0.0555556,0.0277778,0,0.25,1,0.0833333,0.0277778,0,0.375,1,0.111111,0.0277778,0,0.5,1,0.138889,0.0277778,0,0.625,1,0.166667,0.0277778,0,0.75,1,0.194444,0.0277778,0,0.875,1,0.222222,0.0277778,-0.5,1,1,0.25,0.0277778,-0.5,1,0.875,0.277778,0.0277778,-0.5,1,0.75,0.305556,0.0277778,-0.5,1,0.625,0.333333,0.0277778,-0.5,1,0.5,0.361111,0.0277778,-0.5,1,0.375,0.388889,0.0277778,-0.5,1,0.25,0.416667,0.0277778,-0.5,1,0.125,0.444444,0.0277778,1,1,0,0.472222,0.0277778,1,0.875,0,0.5,0.0277778,1,0.75,0,0.527778,0.0277778,1,0.625,0,0.555556,0.0277778,1,0.5,0,0.583333,0.0277778,1,0.375,0,0.611111,0.0277778,1,0.25,0,0.638889,0.0277778,1,0.125,0,0.666667,0.0277778,0.5,0,0,0.694444,0.0277778,0.5,0,0.125,0.722222,0.0277778,0.5,0,0.25,0.75,0.0277778,0.5,0,0.375,0.777778,0.0277778,0.5,0,0.5,0.805556,0.0277778,0.5,0,0.625,0.833333,0.0277778,0.5,0,0.75,0.861111,0.0277778,0.5,0,0.875,0.888889,0.0277778,0,0,1,0.916667,0.0277778,0,0.125,1,0.944444,0.0277778,0,0.25,1,0.972222,0.0277778,0,0.375,1,1,0,0,0.5,1";
      "khotkeysrc"."Data_2_7_4Triggers1"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_7_4Triggers2"."GesturePointData" =
        "0,0.0277778,0.5,0,0.5,0.0277778,0.0277778,0.5,0,0.625,0.0555556,0.0277778,0.5,0,0.75,0.0833333,0.0277778,0.5,0,0.875,0.111111,0.0277778,0,0,1,0.138889,0.0277778,0,0.125,1,0.166667,0.0277778,0,0.25,1,0.194444,0.0277778,0,0.375,1,0.222222,0.0277778,0,0.5,1,0.25,0.0277778,0,0.625,1,0.277778,0.0277778,0,0.75,1,0.305556,0.0277778,0,0.875,1,0.333333,0.0277778,-0.5,1,1,0.361111,0.0277778,-0.5,1,0.875,0.388889,0.0277778,-0.5,1,0.75,0.416667,0.0277778,-0.5,1,0.625,0.444444,0.0277778,-0.5,1,0.5,0.472222,0.0277778,-0.5,1,0.375,0.5,0.0277778,-0.5,1,0.25,0.527778,0.0277778,-0.5,1,0.125,0.555556,0.0277778,1,1,0,0.583333,0.0277778,1,0.875,0,0.611111,0.0277778,1,0.75,0,0.638889,0.0277778,1,0.625,0,0.666667,0.0277778,1,0.5,0,0.694444,0.0277778,1,0.375,0,0.722222,0.0277778,1,0.25,0,0.75,0.0277778,1,0.125,0,0.777778,0.0277778,0.5,0,0,0.805556,0.0277778,0.5,0,0.125,0.833333,0.0277778,0.5,0,0.25,0.861111,0.0277778,0.5,0,0.375,0.888889,0.0277778,0.5,0,0.5,0.916667,0.0277778,0.5,0,0.625,0.944444,0.0277778,0.5,0,0.75,0.972222,0.0277778,0.5,0,0.875,1,0,0,0,1";
      "khotkeysrc"."Data_2_7_4Triggers2"."Type" = "GESTURE";
      "khotkeysrc"."Data_2_8"."Comment" =
        "After pressing Win+E (Tux+E) a WWW browser will be launched, and it will open http://www.kde.org . You may run all kind of commands you can run in minicli (Alt+F2).";
      "khotkeysrc"."Data_2_8"."Enabled" = false;
      "khotkeysrc"."Data_2_8"."Name" = "Go to KDE Website";
      "khotkeysrc"."Data_2_8"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_2_8Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_2_8Actions0"."CommandURL" = "http://www.kde.org";
      "khotkeysrc"."Data_2_8Actions0"."Type" = "COMMAND_URL";
      "khotkeysrc"."Data_2_8Conditions"."Comment" = "";
      "khotkeysrc"."Data_2_8Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_2_8Triggers"."Comment" = "Simple_action";
      "khotkeysrc"."Data_2_8Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_2_8Triggers0"."Key" = "Meta+E";
      "khotkeysrc"."Data_2_8Triggers0"."Type" = "SHORTCUT";
      "khotkeysrc"."Data_2_8Triggers0"."Uuid" =
        "{c2763091-a5c2-46c6-bb24-cb2f4538f564}";
      "khotkeysrc"."Data_3"."Comment" = "Basic Konqueror gestures.";
      "khotkeysrc"."Data_3"."DataCount" = 14;
      "khotkeysrc"."Data_3"."Enabled" = true;
      "khotkeysrc"."Data_3"."ImportId" = "konqueror_gestures_kde321";
      "khotkeysrc"."Data_3"."Name" = "Konqueror Gestures";
      "khotkeysrc"."Data_3"."SystemGroup" = 0;
      "khotkeysrc"."Data_3"."Type" = "ACTION_DATA_GROUP";
      "khotkeysrc"."Data_3Conditions"."Comment" = "Konqueror window";
      "khotkeysrc"."Data_3Conditions"."ConditionsCount" = 1;
      "khotkeysrc"."Data_3Conditions0"."Type" = "ACTIVE_WINDOW";
      "khotkeysrc"."Data_3Conditions0Window"."Comment" = "Konqueror";
      "khotkeysrc"."Data_3Conditions0Window"."WindowsCount" = 1;
      "khotkeysrc"."Data_3Conditions0Window0"."Class" = "^konquerors";
      "khotkeysrc"."Data_3Conditions0Window0"."ClassType" = 3;
      "khotkeysrc"."Data_3Conditions0Window0"."Comment" = "Konqueror";
      "khotkeysrc"."Data_3Conditions0Window0"."Role" = "konqueror-mainwindow#1";
      "khotkeysrc"."Data_3Conditions0Window0"."RoleType" = 0;
      "khotkeysrc"."Data_3Conditions0Window0"."Title" = "file:/ - Konqueror";
      "khotkeysrc"."Data_3Conditions0Window0"."TitleType" = 0;
      "khotkeysrc"."Data_3Conditions0Window0"."Type" = "SIMPLE";
      "khotkeysrc"."Data_3Conditions0Window0"."WindowTypes" = 1;
      "khotkeysrc"."Data_3_1"."Comment" = "Press, move left, release.";
      "khotkeysrc"."Data_3_1"."Enabled" = true;
      "khotkeysrc"."Data_3_1"."Name" = "Back";
      "khotkeysrc"."Data_3_1"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_10"."Comment" = ''
        Opera-style: Press, move up, release.
        NOTE: Conflicts with 'New Tab', and as such is disabled by default.'';
      "khotkeysrc"."Data_3_10"."Enabled" = false;
      "khotkeysrc"."Data_3_10"."Name" = "Stop Loading";
      "khotkeysrc"."Data_3_10"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_10Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_10Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_10Actions0"."Input" = ''
        Escape
      '';
      "khotkeysrc"."Data_3_10Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_10Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_10Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_10Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_10Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_10Triggers0"."GesturePointData" =
        "0,0.125,-0.5,0.5,1,0.125,0.125,-0.5,0.5,0.875,0.25,0.125,-0.5,0.5,0.75,0.375,0.125,-0.5,0.5,0.625,0.5,0.125,-0.5,0.5,0.5,0.625,0.125,-0.5,0.5,0.375,0.75,0.125,-0.5,0.5,0.25,0.875,0.125,-0.5,0.5,0.125,1,0,0,0.5,0";
      "khotkeysrc"."Data_3_10Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_11"."Comment" = ''
        Going up in URL/directory structure.
        Mozilla-style: Press, move up, move left, move up, release.'';
      "khotkeysrc"."Data_3_11"."Enabled" = true;
      "khotkeysrc"."Data_3_11"."Name" = "Up";
      "khotkeysrc"."Data_3_11"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_11Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_11Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_11Actions0"."Input" = "Alt+Up";
      "khotkeysrc"."Data_3_11Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_11Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_11Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_11Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_11Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_11Triggers0"."GesturePointData" =
        "0,0.0625,-0.5,1,1,0.0625,0.0625,-0.5,1,0.875,0.125,0.0625,-0.5,1,0.75,0.1875,0.0625,-0.5,1,0.625,0.25,0.0625,1,1,0.5,0.3125,0.0625,1,0.875,0.5,0.375,0.0625,1,0.75,0.5,0.4375,0.0625,1,0.625,0.5,0.5,0.0625,1,0.5,0.5,0.5625,0.0625,1,0.375,0.5,0.625,0.0625,1,0.25,0.5,0.6875,0.0625,1,0.125,0.5,0.75,0.0625,-0.5,0,0.5,0.8125,0.0625,-0.5,0,0.375,0.875,0.0625,-0.5,0,0.25,0.9375,0.0625,-0.5,0,0.125,1,0,0,0,0";
      "khotkeysrc"."Data_3_11Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_12"."Comment" = ''
        Going up in URL/directory structure.
        Opera-style: Press, move up, move left, move up, release.
        NOTE: Conflicts with  "Activate Previous Tab", and as such is disabled by default.'';
      "khotkeysrc"."Data_3_12"."Enabled" = false;
      "khotkeysrc"."Data_3_12"."Name" = "Up #2";
      "khotkeysrc"."Data_3_12"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_12Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_12Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_12Actions0"."Input" = ''
        Alt+Up
      '';
      "khotkeysrc"."Data_3_12Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_12Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_12Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_12Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_12Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_12Triggers0"."GesturePointData" =
        "0,0.0625,-0.5,1,1,0.0625,0.0625,-0.5,1,0.875,0.125,0.0625,-0.5,1,0.75,0.1875,0.0625,-0.5,1,0.625,0.25,0.0625,-0.5,1,0.5,0.3125,0.0625,-0.5,1,0.375,0.375,0.0625,-0.5,1,0.25,0.4375,0.0625,-0.5,1,0.125,0.5,0.0625,1,1,0,0.5625,0.0625,1,0.875,0,0.625,0.0625,1,0.75,0,0.6875,0.0625,1,0.625,0,0.75,0.0625,1,0.5,0,0.8125,0.0625,1,0.375,0,0.875,0.0625,1,0.25,0,0.9375,0.0625,1,0.125,0,1,0,0,0,0";
      "khotkeysrc"."Data_3_12Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_13"."Comment" =
        "Press, move up, move right, release.";
      "khotkeysrc"."Data_3_13"."Enabled" = true;
      "khotkeysrc"."Data_3_13"."Name" = "Activate Next Tab";
      "khotkeysrc"."Data_3_13"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_13Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_13Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_13Actions0"."Input" = ''
        Ctrl+.
      '';
      "khotkeysrc"."Data_3_13Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_13Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_13Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_13Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_13Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_13Triggers0"."GesturePointData" =
        "0,0.0625,-0.5,0,1,0.0625,0.0625,-0.5,0,0.875,0.125,0.0625,-0.5,0,0.75,0.1875,0.0625,-0.5,0,0.625,0.25,0.0625,-0.5,0,0.5,0.3125,0.0625,-0.5,0,0.375,0.375,0.0625,-0.5,0,0.25,0.4375,0.0625,-0.5,0,0.125,0.5,0.0625,0,0,0,0.5625,0.0625,0,0.125,0,0.625,0.0625,0,0.25,0,0.6875,0.0625,0,0.375,0,0.75,0.0625,0,0.5,0,0.8125,0.0625,0,0.625,0,0.875,0.0625,0,0.75,0,0.9375,0.0625,0,0.875,0,1,0,0,1,0";
      "khotkeysrc"."Data_3_13Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_14"."Comment" =
        "Press, move up, move left, release.";
      "khotkeysrc"."Data_3_14"."Enabled" = true;
      "khotkeysrc"."Data_3_14"."Name" = "Activate Previous Tab";
      "khotkeysrc"."Data_3_14"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_14Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_14Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_14Actions0"."Input" = "Ctrl+,";
      "khotkeysrc"."Data_3_14Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_14Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_14Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_14Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_14Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_14Triggers0"."GesturePointData" =
        "0,0.0625,-0.5,1,1,0.0625,0.0625,-0.5,1,0.875,0.125,0.0625,-0.5,1,0.75,0.1875,0.0625,-0.5,1,0.625,0.25,0.0625,-0.5,1,0.5,0.3125,0.0625,-0.5,1,0.375,0.375,0.0625,-0.5,1,0.25,0.4375,0.0625,-0.5,1,0.125,0.5,0.0625,1,1,0,0.5625,0.0625,1,0.875,0,0.625,0.0625,1,0.75,0,0.6875,0.0625,1,0.625,0,0.75,0.0625,1,0.5,0,0.8125,0.0625,1,0.375,0,0.875,0.0625,1,0.25,0,0.9375,0.0625,1,0.125,0,1,0,0,0,0";
      "khotkeysrc"."Data_3_14Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_1Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_1Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_1Actions0"."Input" = "Alt+Left";
      "khotkeysrc"."Data_3_1Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_1Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_1Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_1Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_1Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_1Triggers0"."GesturePointData" =
        "0,0.125,1,1,0.5,0.125,0.125,1,0.875,0.5,0.25,0.125,1,0.75,0.5,0.375,0.125,1,0.625,0.5,0.5,0.125,1,0.5,0.5,0.625,0.125,1,0.375,0.5,0.75,0.125,1,0.25,0.5,0.875,0.125,1,0.125,0.5,1,0,0,0,0.5";
      "khotkeysrc"."Data_3_1Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_2"."Comment" =
        "Press, move down, move up, move down, release.";
      "khotkeysrc"."Data_3_2"."Enabled" = true;
      "khotkeysrc"."Data_3_2"."Name" = "Duplicate Tab";
      "khotkeysrc"."Data_3_2"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_2Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_2Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_2Actions0"."Input" = ''
        Ctrl+Shift+D
      '';
      "khotkeysrc"."Data_3_2Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_2Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_2Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_2Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_2Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_2Triggers0"."GesturePointData" =
        "0,0.0416667,0.5,0.5,0,0.0416667,0.0416667,0.5,0.5,0.125,0.0833333,0.0416667,0.5,0.5,0.25,0.125,0.0416667,0.5,0.5,0.375,0.166667,0.0416667,0.5,0.5,0.5,0.208333,0.0416667,0.5,0.5,0.625,0.25,0.0416667,0.5,0.5,0.75,0.291667,0.0416667,0.5,0.5,0.875,0.333333,0.0416667,-0.5,0.5,1,0.375,0.0416667,-0.5,0.5,0.875,0.416667,0.0416667,-0.5,0.5,0.75,0.458333,0.0416667,-0.5,0.5,0.625,0.5,0.0416667,-0.5,0.5,0.5,0.541667,0.0416667,-0.5,0.5,0.375,0.583333,0.0416667,-0.5,0.5,0.25,0.625,0.0416667,-0.5,0.5,0.125,0.666667,0.0416667,0.5,0.5,0,0.708333,0.0416667,0.5,0.5,0.125,0.75,0.0416667,0.5,0.5,0.25,0.791667,0.0416667,0.5,0.5,0.375,0.833333,0.0416667,0.5,0.5,0.5,0.875,0.0416667,0.5,0.5,0.625,0.916667,0.0416667,0.5,0.5,0.75,0.958333,0.0416667,0.5,0.5,0.875,1,0,0,0.5,1";
      "khotkeysrc"."Data_3_2Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_3"."Comment" = "Press, move down, move up, release.";
      "khotkeysrc"."Data_3_3"."Enabled" = true;
      "khotkeysrc"."Data_3_3"."Name" = "Duplicate Window";
      "khotkeysrc"."Data_3_3"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_3Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_3Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_3Actions0"."Input" = ''
        Ctrl+D
      '';
      "khotkeysrc"."Data_3_3Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_3Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_3Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_3Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_3Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_3Triggers0"."GesturePointData" =
        "0,0.0625,0.5,0.5,0,0.0625,0.0625,0.5,0.5,0.125,0.125,0.0625,0.5,0.5,0.25,0.1875,0.0625,0.5,0.5,0.375,0.25,0.0625,0.5,0.5,0.5,0.3125,0.0625,0.5,0.5,0.625,0.375,0.0625,0.5,0.5,0.75,0.4375,0.0625,0.5,0.5,0.875,0.5,0.0625,-0.5,0.5,1,0.5625,0.0625,-0.5,0.5,0.875,0.625,0.0625,-0.5,0.5,0.75,0.6875,0.0625,-0.5,0.5,0.625,0.75,0.0625,-0.5,0.5,0.5,0.8125,0.0625,-0.5,0.5,0.375,0.875,0.0625,-0.5,0.5,0.25,0.9375,0.0625,-0.5,0.5,0.125,1,0,0,0.5,0";
      "khotkeysrc"."Data_3_3Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_4"."Comment" = "Press, move right, release.";
      "khotkeysrc"."Data_3_4"."Enabled" = true;
      "khotkeysrc"."Data_3_4"."Name" = "Forward";
      "khotkeysrc"."Data_3_4"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_4Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_4Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_4Actions0"."Input" = "Alt+Right";
      "khotkeysrc"."Data_3_4Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_4Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_4Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_4Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_4Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_4Triggers0"."GesturePointData" =
        "0,0.125,0,0,0.5,0.125,0.125,0,0.125,0.5,0.25,0.125,0,0.25,0.5,0.375,0.125,0,0.375,0.5,0.5,0.125,0,0.5,0.5,0.625,0.125,0,0.625,0.5,0.75,0.125,0,0.75,0.5,0.875,0.125,0,0.875,0.5,1,0,0,1,0.5";
      "khotkeysrc"."Data_3_4Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_5"."Comment" = ''
        Press, move down, move half up, move right, move down, release.
        (Drawing a lowercase 'h'.)'';
      "khotkeysrc"."Data_3_5"."Enabled" = true;
      "khotkeysrc"."Data_3_5"."Name" = "Home";
      "khotkeysrc"."Data_3_5"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_5Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_5Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_5Actions0"."Input" = ''
        Alt+Home
      '';
      "khotkeysrc"."Data_3_5Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_5Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_5Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_5Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_5Triggers"."TriggersCount" = 2;
      "khotkeysrc"."Data_3_5Triggers0"."GesturePointData" =
        "0,0.0461748,0.5,0,0,0.0461748,0.0461748,0.5,0,0.125,0.0923495,0.0461748,0.5,0,0.25,0.138524,0.0461748,0.5,0,0.375,0.184699,0.0461748,0.5,0,0.5,0.230874,0.0461748,0.5,0,0.625,0.277049,0.0461748,0.5,0,0.75,0.323223,0.0461748,0.5,0,0.875,0.369398,0.065301,-0.25,0,1,0.434699,0.065301,-0.25,0.125,0.875,0.5,0.065301,-0.25,0.25,0.75,0.565301,0.065301,-0.25,0.375,0.625,0.630602,0.0461748,0,0.5,0.5,0.676777,0.0461748,0,0.625,0.5,0.722951,0.0461748,0,0.75,0.5,0.769126,0.0461748,0,0.875,0.5,0.815301,0.0461748,0.5,1,0.5,0.861476,0.0461748,0.5,1,0.625,0.90765,0.0461748,0.5,1,0.75,0.953825,0.0461748,0.5,1,0.875,1,0,0,1,1";
      "khotkeysrc"."Data_3_5Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_5Triggers1"."GesturePointData" =
        "0,0.0416667,0.5,0,0,0.0416667,0.0416667,0.5,0,0.125,0.0833333,0.0416667,0.5,0,0.25,0.125,0.0416667,0.5,0,0.375,0.166667,0.0416667,0.5,0,0.5,0.208333,0.0416667,0.5,0,0.625,0.25,0.0416667,0.5,0,0.75,0.291667,0.0416667,0.5,0,0.875,0.333333,0.0416667,-0.5,0,1,0.375,0.0416667,-0.5,0,0.875,0.416667,0.0416667,-0.5,0,0.75,0.458333,0.0416667,-0.5,0,0.625,0.5,0.0416667,0,0,0.5,0.541667,0.0416667,0,0.125,0.5,0.583333,0.0416667,0,0.25,0.5,0.625,0.0416667,0,0.375,0.5,0.666667,0.0416667,0,0.5,0.5,0.708333,0.0416667,0,0.625,0.5,0.75,0.0416667,0,0.75,0.5,0.791667,0.0416667,0,0.875,0.5,0.833333,0.0416667,0.5,1,0.5,0.875,0.0416667,0.5,1,0.625,0.916667,0.0416667,0.5,1,0.75,0.958333,0.0416667,0.5,1,0.875,1,0,0,1,1";
      "khotkeysrc"."Data_3_5Triggers1"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_6"."Comment" = ''
        Press, move right, move down, move right, release.
        Mozilla-style: Press, move down, move right, release.'';
      "khotkeysrc"."Data_3_6"."Enabled" = true;
      "khotkeysrc"."Data_3_6"."Name" = "Close Tab";
      "khotkeysrc"."Data_3_6"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_6Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_6Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_6Actions0"."Input" = ''
        Ctrl+W
      '';
      "khotkeysrc"."Data_3_6Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_6Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_6Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_6Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_6Triggers"."TriggersCount" = 2;
      "khotkeysrc"."Data_3_6Triggers0"."GesturePointData" =
        "0,0.0625,0,0,0,0.0625,0.0625,0,0.125,0,0.125,0.0625,0,0.25,0,0.1875,0.0625,0,0.375,0,0.25,0.0625,0.5,0.5,0,0.3125,0.0625,0.5,0.5,0.125,0.375,0.0625,0.5,0.5,0.25,0.4375,0.0625,0.5,0.5,0.375,0.5,0.0625,0.5,0.5,0.5,0.5625,0.0625,0.5,0.5,0.625,0.625,0.0625,0.5,0.5,0.75,0.6875,0.0625,0.5,0.5,0.875,0.75,0.0625,0,0.5,1,0.8125,0.0625,0,0.625,1,0.875,0.0625,0,0.75,1,0.9375,0.0625,0,0.875,1,1,0,0,1,1";
      "khotkeysrc"."Data_3_6Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_6Triggers1"."GesturePointData" =
        "0,0.0625,0.5,0,0,0.0625,0.0625,0.5,0,0.125,0.125,0.0625,0.5,0,0.25,0.1875,0.0625,0.5,0,0.375,0.25,0.0625,0.5,0,0.5,0.3125,0.0625,0.5,0,0.625,0.375,0.0625,0.5,0,0.75,0.4375,0.0625,0.5,0,0.875,0.5,0.0625,0,0,1,0.5625,0.0625,0,0.125,1,0.625,0.0625,0,0.25,1,0.6875,0.0625,0,0.375,1,0.75,0.0625,0,0.5,1,0.8125,0.0625,0,0.625,1,0.875,0.0625,0,0.75,1,0.9375,0.0625,0,0.875,1,1,0,0,1,1";
      "khotkeysrc"."Data_3_6Triggers1"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_7"."Comment" = ''
        Press, move up, release.
        Conflicts with Opera-style 'Up #2', which is disabled by default.'';
      "khotkeysrc"."Data_3_7"."Enabled" = true;
      "khotkeysrc"."Data_3_7"."Name" = "New Tab";
      "khotkeysrc"."Data_3_7"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_7Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_7Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_7Actions0"."Input" = "Ctrl+Shift+N";
      "khotkeysrc"."Data_3_7Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_7Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_7Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_7Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_7Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_7Triggers0"."GesturePointData" =
        "0,0.125,-0.5,0.5,1,0.125,0.125,-0.5,0.5,0.875,0.25,0.125,-0.5,0.5,0.75,0.375,0.125,-0.5,0.5,0.625,0.5,0.125,-0.5,0.5,0.5,0.625,0.125,-0.5,0.5,0.375,0.75,0.125,-0.5,0.5,0.25,0.875,0.125,-0.5,0.5,0.125,1,0,0,0.5,0";
      "khotkeysrc"."Data_3_7Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_8"."Comment" = "Press, move down, release.";
      "khotkeysrc"."Data_3_8"."Enabled" = true;
      "khotkeysrc"."Data_3_8"."Name" = "New Window";
      "khotkeysrc"."Data_3_8"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_8Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_8Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_8Actions0"."Input" = ''
        Ctrl+N
      '';
      "khotkeysrc"."Data_3_8Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_8Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_8Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_8Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_8Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_8Triggers0"."GesturePointData" =
        "0,0.125,0.5,0.5,0,0.125,0.125,0.5,0.5,0.125,0.25,0.125,0.5,0.5,0.25,0.375,0.125,0.5,0.5,0.375,0.5,0.125,0.5,0.5,0.5,0.625,0.125,0.5,0.5,0.625,0.75,0.125,0.5,0.5,0.75,0.875,0.125,0.5,0.5,0.875,1,0,0,0.5,1";
      "khotkeysrc"."Data_3_8Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."Data_3_9"."Comment" = "Press, move up, move down, release.";
      "khotkeysrc"."Data_3_9"."Enabled" = true;
      "khotkeysrc"."Data_3_9"."Name" = "Reload";
      "khotkeysrc"."Data_3_9"."Type" = "SIMPLE_ACTION_DATA";
      "khotkeysrc"."Data_3_9Actions"."ActionsCount" = 1;
      "khotkeysrc"."Data_3_9Actions0"."DestinationWindow" = 2;
      "khotkeysrc"."Data_3_9Actions0"."Input" = "F5";
      "khotkeysrc"."Data_3_9Actions0"."Type" = "KEYBOARD_INPUT";
      "khotkeysrc"."Data_3_9Conditions"."Comment" = "";
      "khotkeysrc"."Data_3_9Conditions"."ConditionsCount" = 0;
      "khotkeysrc"."Data_3_9Triggers"."Comment" = "Gesture_triggers";
      "khotkeysrc"."Data_3_9Triggers"."TriggersCount" = 1;
      "khotkeysrc"."Data_3_9Triggers0"."GesturePointData" =
        "0,0.0625,-0.5,0.5,1,0.0625,0.0625,-0.5,0.5,0.875,0.125,0.0625,-0.5,0.5,0.75,0.1875,0.0625,-0.5,0.5,0.625,0.25,0.0625,-0.5,0.5,0.5,0.3125,0.0625,-0.5,0.5,0.375,0.375,0.0625,-0.5,0.5,0.25,0.4375,0.0625,-0.5,0.5,0.125,0.5,0.0625,0.5,0.5,0,0.5625,0.0625,0.5,0.5,0.125,0.625,0.0625,0.5,0.5,0.25,0.6875,0.0625,0.5,0.5,0.375,0.75,0.0625,0.5,0.5,0.5,0.8125,0.0625,0.5,0.5,0.625,0.875,0.0625,0.5,0.5,0.75,0.9375,0.0625,0.5,0.5,0.875,1,0,0,0.5,1";
      "khotkeysrc"."Data_3_9Triggers0"."Type" = "GESTURE";
      "khotkeysrc"."DirSelect Dialog"."DirSelectDialog Size[$d]" = "";
      "khotkeysrc"."General.$i"."AccentColor[$di]" = "";
      "khotkeysrc"."General.$i"."AccentColorx5b$dx5d[$i]" = "";

      "khotkeysrc"."General.$i"."AllowKDEAppsToRememberWindowPositions[$di]" =
        "";
      "khotkeysrc"."General.$i"."AllowKDEAppsToRememberWindowPositionsx5b$dx5d[$i]" =
        "";
      "khotkeysrc"."General.$i"."BrowserApplication[$di]" = "";
      "khotkeysrc"."General.$i"."BrowserApplicationx5b$dx5d[$i]" = "";
      "khotkeysrc"."General.$i"."ColorSchemeHash[$di]" = "";
      "khotkeysrc"."General.$i"."ColorSchemeHashx5b$dx5d[$i]" = "";

      "khotkeysrc"."General.$i"."ColorScheme[$di]" = "";
      "khotkeysrc"."General.$i"."ColorSchemex5b$dx5d[$i]" = "";

      "khotkeysrc"."General.$i"."LastUsedCustomAccentColor[$di]" = "";
      "khotkeysrc"."General.$i"."LastUsedCustomAccentColorx5b$dx5d[$i]" = "";
      "khotkeysrc"."General.$i"."XftHintStyle[$di]" = "";
      "khotkeysrc"."General.$i"."XftSubPixel[$di]" = "";
      "khotkeysrc"."General.$i"."accentColorFromWallpaper[$di]" = "";
      "khotkeysrc"."General.$i"."font[$di]" = "";
      "khotkeysrc"."Gestures"."Disabled" = true;
      "khotkeysrc"."Gestures"."MouseButton" = 2;
      "khotkeysrc"."Gestures"."Timeout" = 300;
      "khotkeysrc"."GesturesExclude"."Comment" = "";
      "khotkeysrc"."GesturesExclude"."WindowsCount" = 0;
      "khotkeysrc"."Icons"."Theme[$d]" = "";
      "khotkeysrc"."KDE"."LookAndFeelPackage[$d]" = "";
      "khotkeysrc"."KDE"."ScrollbarLeftClickNavigatesByPage[$d]" = "";
      "khotkeysrc"."KDE"."SingleClick[$d]" = "";
      "khotkeysrc"."KDE"."widgetStyle[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Allow Expansion[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Automatically select filename extension[$d]" =
        "";
      "khotkeysrc"."KFileDialog Settings"."Breadcrumb Navigation[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Decoration position[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."LocationCombo Completionmode[$d]" =
        "";
      "khotkeysrc"."KFileDialog Settings"."PathCombo Completionmode[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Show Bookmarks[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Show Full Path[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Show Inline Previews[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Show Preview[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Show Speedbar[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Show hidden files[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Sort by[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Sort directories first[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Sort hidden files last[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Sort reversed[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."Speedbar Width[$d]" = "";
      "khotkeysrc"."KFileDialog Settings"."View Style[$d]" = "";
      "khotkeysrc"."KScreen"."ScreenScaleFactors[$d]" = "";
      "khotkeysrc"."KScreen"."XwaylandClientsScale[$d]" = "";
      "khotkeysrc"."Main"."AlreadyImported" =
        "defaults,kde32b1,konqueror_gestures_kde321";
      "khotkeysrc"."Main"."Disabled" = false;
      "khotkeysrc"."Shortcuts"."Reload[$d]" = "";
      "khotkeysrc"."Voice"."Shortcut" = "";
      "khotkeysrc"."WM.$i"."activeBackground[$di]" = "";
      "khotkeysrc"."WM.$i"."activeBlend[$di]" = "";
      "khotkeysrc"."WM.$i"."activeForeground[$di]" = "";
      "khotkeysrc"."WM.$i"."frame[$di]" = "";
      "khotkeysrc"."WM.$i"."framex5b$dx5d[$i]" = "";
      "khotkeysrc"."WM.$i"."inactiveBackground[$di]" = "";
      "khotkeysrc"."WM.$i"."inactiveBackgroundx5b$dx5d[$i]" = "";
      "khotkeysrc"."WM.$i"."inactiveBlend[$di]" = "";
      "khotkeysrc"."WM.$i"."inactiveForeground[$di]" = "";
      "khotkeysrc"."WM.$i"."inactiveFrame[$di]" = "";
      "khotkeysrc"."WM.$i"."inactiveFramex5b$dx5d[$i]" = "";
      "kiorc"."Confirmations"."ConfirmDelete" = true;
      "kiorc"."Confirmations"."ConfirmEmptyTrash" = true;
      "kiorc"."Executable scripts"."behaviourOnLaunch" = "execute";
      "klipperrc"."General"."IgnoreImages" = false;
      "klipperrc"."General"."MaxClipItems" = 999;
      "krunnerrc"."General"."FreeFloating" = true;
      "krunnerrc"."Plugins"."CharacterRunnerEnabled" = false;
      "krunnerrc"."Plugins"."DictionaryEnabled" = false;
      "krunnerrc"."Plugins"."PowerDevilEnabled" = false;
      "krunnerrc"."Plugins"."appstreamEnabled" = false;
      "krunnerrc"."Plugins"."baloosearchEnabled" = false;
      "krunnerrc"."Plugins"."bookmarksEnabled" = false;
      "krunnerrc"."Plugins"."browserhistoryEnabled" = false;
      "krunnerrc"."Plugins"."browsertabsEnabled" = false;
      "krunnerrc"."Plugins"."helprunnerEnabled" = false;
      "krunnerrc"."Plugins"."katesessionsEnabled" = false;
      "krunnerrc"."Plugins"."konsoleprofilesEnabled" = false;
      "krunnerrc"."Plugins"."krunner_killEnabled" = false;
      "krunnerrc"."Plugins"."krunner_spellcheckEnabled" = false;
      "krunnerrc"."Plugins"."kwinEnabled" = false;
      "krunnerrc"."Plugins"."locationsEnabled" = false;
      "krunnerrc"."Plugins"."org.kde.activities2Enabled" = false;
      "krunnerrc"."Plugins"."org.kde.windowedwidgetsEnabled" = false;
      "krunnerrc"."Plugins"."placesEnabled" = false;
      "krunnerrc"."Plugins"."plasma-desktopEnabled" = false;
      "krunnerrc"."Plugins"."recentdocumentsEnabled" = false;
      "krunnerrc"."Plugins"."webshortcutsEnabled" = false;
      "krunnerrc"."Plugins"."windowsEnabled" = false;
      "kscreenlockerrc"."Daemon"."Autolock" = false;
      "kscreenlockerrc"."Daemon"."LockOnResume" = false;
      "kwalletrc"."Wallet"."Close When Idle" = false;
      "kwalletrc"."Wallet"."Close on Screensaver" = false;
      "kwalletrc"."Wallet"."Default Wallet" = "kdewallet";
      "kwalletrc"."Wallet"."Enabled" = false;
      "kwalletrc"."Wallet"."First Use" = false;
      "kwalletrc"."Wallet"."Idle Timeout" = 10;
      "kwalletrc"."Wallet"."Launch Manager" = false;
      "kwalletrc"."Wallet"."Leave Manager Open" = false;
      "kwalletrc"."Wallet"."Leave Open" = true;
      "kwalletrc"."Wallet"."Prompt on Open" = false;
      "kwalletrc"."Wallet"."Use One Wallet" = true;
      "kwalletrc"."org.freedesktop.secrets"."apiEnabled" = true;
      "kwinrc"."Desktops"."Id_1" = "664200de-6817-4c11-beff-ffeb88847b95";
      "kwinrc"."Desktops"."Id_2" = "b4e02a93-aa4e-49b6-9525-73f0ab13b8ca";
      "kwinrc"."Desktops"."Id_3" = "e1d452e4-8f3a-40d7-afd6-0dc576f025e4";
      "kwinrc"."Desktops"."Name_1" = "Desktop 2";
      "kwinrc"."Desktops"."Number" = 3;
      "kwinrc"."Desktops"."Rows" = 1;
      "kwinrc"."Effect-blur"."BlurStrength" = 11;
      "kwinrc"."Effect-blur"."NoiseStrength" = 0;
      "kwinrc"."Effect-kwin4_effect_geometry_change"."Duration" = 550;
      "kwinrc"."Effect-kwin4_effect_tv_glitch"."Duration" = 550;
      "kwinrc"."Effect-kwin4_effect_tv_glitch"."Speed" = 1;
      "kwinrc"."Effect-kwin4_effect_tv_glitch"."Strength" = 1;
      "kwinrc"."Effect-magiclamp"."AnimationDuration" = 400;
      "kwinrc"."Effect-windowview"."BorderActivateAll" = 9;
      "kwinrc"."Effect-wobblywindows"."AdvancedMode" = true;
      "kwinrc"."Effect-wobblywindows"."Drag" = 92;
      "kwinrc"."Effect-wobblywindows"."MoveFactor" = 20;
      "kwinrc"."Effect-wobblywindows"."Stiffness" = 3;
      "kwinrc"."Effect-wobblywindows"."WobblynessLevel" = 3;
      "kwinrc"."ModifierOnlyShortcuts"."Meta" = "";
      "kwinrc"."MouseBindings"."CommandAllWheel" = "Change Opacity";
      "kwinrc"."Plugins"."activatelattelaunchermenuEnabled" = true;
      "kwinrc"."Plugins"."bismuthEnabled" = true;
      "kwinrc"."Plugins"."blurEnabled" = true;
      "kwinrc"."Plugins"."force-decorations-gtk3Enabled" = true;
      "kwinrc"."Plugins"."forceblurEnabled" = true;
      "kwinrc"."Plugins"."karouselEnabled" = false;
      "kwinrc"."Plugins"."kwin4_effect_dimscreenEnabled" = true;
      "kwinrc"."Plugins"."kwin4_effect_geometry_changeEnabled" = true;
      "kwinrc"."Plugins"."kwin4_effect_maximizeEnabled" = false;
      "kwinrc"."Plugins"."kwin4_effect_scaleEnabled" = false;
      "kwinrc"."Plugins"."kwin4_effect_squashEnabled" = false;
      "kwinrc"."Plugins"."kwin4_effect_tv_glitchEnabled" = true;
      "kwinrc"."Plugins"."lattewindowcolorsEnabled" = true;
      "kwinrc"."Plugins"."macsimizeEnabled" = false;
      "kwinrc"."Plugins"."magiclampEnabled" = true;
      "kwinrc"."Plugins"."max2NewVirtualDesktopEnabled" = false;
      "kwinrc"."Plugins"."poloniumEnabled" = true;
      "kwinrc"."Plugins"."screenedgeEnabled" = false;
      "kwinrc"."Plugins"."wobblywindowsEnabled" = true;
      "kwinrc"."Script-bismuth"."enableFloatingLayout" = true;
      "kwinrc"."Script-bismuth"."enableQuarterLayout" = true;
      "kwinrc"."Script-bismuth"."floatingClass" =
        "yakuake,spectacle,Conky,zoom,tdrop_terminal,copyq,Steam,lutris, steam,steam_app.*, Steam,Warframe,lutris,Riot Client Main,League of Legends, weixin, .scrcpy-wrapped,zenity,org.kde.polkit-kde-authentication-agent-1";
      "kwinrc"."Script-bismuth"."floatingTitle" = "Steam, Warframe";
      "kwinrc"."Script-bismuth"."ignoreClass" = "";
      "kwinrc"."Script-bismuth"."ignoreRole" = "";
      "kwinrc"."Script-bismuth"."newWindowAsMaster" = true;
      "kwinrc"."Script-bismuth"."screenGapBottom" = 20;
      "kwinrc"."Script-bismuth"."screenGapLeft" = 20;
      "kwinrc"."Script-bismuth"."screenGapRight" = 20;
      "kwinrc"."Script-bismuth"."screenGapTop" = 20;
      "kwinrc"."Script-bismuth"."tileLayoutGap" = 20;
      "kwinrc"."Script-forceblur"."blurExceptMatching" = true;
      "kwinrc"."Script-forceblur"."blurMatching" = false;
      "kwinrc"."Script-forceblur"."patterns" = "";
      "kwinrc"."Script-karousel"."gapsInnerHorizontal" = 10;
      "kwinrc"."Script-karousel"."gapsInnerVertical" = 10;
      "kwinrc"."Script-karousel"."gapsOuterLeft" = 10;
      "kwinrc"."Script-karousel"."gapsOuterRight" = 10;
      "kwinrc"."Script-karousel"."manualScrollStep" = 500;
      "kwinrc"."Script-karousel"."overscroll" = 10;
      "kwinrc"."Script-max2NewVirtualDesktop"."newDesktopPosition" =
        "NextToCurrent";
      "kwinrc"."Script-max2NewVirtualDesktop"."trigger" =
        "FullscreenAndMaximize";
      "kwinrc"."TabBox"."ActivitiesMode" = 0;
      "kwinrc"."TabBox"."DesktopMode" = 0;
      "kwinrc"."TabBox"."LayoutName" = "flipswitch";
      "kwinrc"."TabBoxAlternative"."ActivitiesMode" = 0;
      "kwinrc"."TabBoxAlternative"."DesktopMode" = 0;
      "kwinrc"."TabBoxAlternative"."LayoutName" = "flipswitch";
      "kwinrc"."Tiling"."padding" = 4;
      "kwinrc"."Tiling.0f38bce7-c408-5617-8a30-80a91bfd5f70"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.347893a2-fd0a-5ea3-bdb9-b090bcdf3441"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.3482df95-593c-592a-a0fe-2d76fd4954cc"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.55d40f27-6609-5df3-8294-803a0e9eb223"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.58ca410b-ce44-58d6-82b9-fefe44aba0e3"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.65d2638f-fc90-5a12-83e4-fe70567603cf"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.737d9ef7-347c-5090-903e-2486a474bf1e"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.75a7b21b-2d99-5bfc-8558-c99f5b093214"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.7fb8c463-c102-5440-8fb7-5253b26b5d9c"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.81f320cc-8d18-56ce-a575-8a3eafcc9b39"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.901ecfb4-042a-5be4-87a6-2641eac6c290"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.92e842d7-5928-5c43-884a-4912e7cc82ed"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.a5aa6954-fac1-58b7-ae05-a72bd13601b0"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.c8668e9c-2ddc-58c8-a872-602046675a24"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.da43ea0f-263a-5982-821c-10d28ccbdd2b"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.eceae513-3296-539c-b437-e14fc4ae29b9"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling.f5aa25f6-485e-54ff-bc19-778f3ada3433"."tiles" = ''
        {"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Wayland"."InputMethod[$e]" =
        "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";
      "kwinrc"."Wayland"."InputMethodx5b$ex5d" =
        "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";
      "kwinrc"."Windows"."ElectricBorderMaximize" = false;
      "kwinrc"."Windows"."ElectricBorderTiling" = false;
      "kwinrc"."Windows"."RollOverDesktops" = true;
      "kwinrc"."Xwayland"."Scale" = 1.25;
      "kwinrc"."org.kde.kdecoration2"."BorderSize" = "Tiny";
      "kwinrc"."org.kde.kdecoration2"."BorderSizeAuto" = false;
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "MN";
      "kwinrulesrc"."1"."Description" = "min  = 0";
      "kwinrulesrc"."1"."minsize" = "1,1";
      "kwinrulesrc"."1"."minsizerule" = 2;
      "kwinrulesrc"."1"."wmclass" = "^(?!.*krunner).*$";
      "kwinrulesrc"."1"."wmclassmatch" = 3;
      "kwinrulesrc"."2"."Description" = "trans";
      "kwinrulesrc"."2"."opacityactive" = 90;
      "kwinrulesrc"."2"."opacityactiverule" = 2;
      "kwinrulesrc"."2"."opacityinactive" = 90;
      "kwinrulesrc"."2"."opacityinactiverule" = 2;
      "kwinrulesrc"."2"."wmclassmatch" = 1;
      "kwinrulesrc"."3"."Description" = "force border";
      "kwinrulesrc"."3"."noborderrule" = 2;
      "kwinrulesrc"."43d11804-f330-4d9f-aca2-d51617de4867"."Description" =
        "force border";
      "kwinrulesrc"."43d11804-f330-4d9f-aca2-d51617de4867"."noborderrule" = 2;
      "kwinrulesrc"."48304a6e-f9b6-4980-b37e-174d343b57ac"."Description" =
        "trans";
      "kwinrulesrc"."48304a6e-f9b6-4980-b37e-174d343b57ac"."opacityactive" = 90;
      "kwinrulesrc"."48304a6e-f9b6-4980-b37e-174d343b57ac"."opacityactiverule" =
        2;
      "kwinrulesrc"."48304a6e-f9b6-4980-b37e-174d343b57ac"."opacityinactive" =
        90;
      "kwinrulesrc"."48304a6e-f9b6-4980-b37e-174d343b57ac"."opacityinactiverule" =
        2;
      "kwinrulesrc"."5521958f-1d4d-456d-ac10-f3886c37f858"."Description" =
        "force ssd";
      "kwinrulesrc"."5521958f-1d4d-456d-ac10-f3886c37f858"."noborderrule" = 2;
      "kwinrulesrc"."6677ad57-ece4-448e-b9ca-d81d7ab98c13"."Description" =
        "min  = 0";
      "kwinrulesrc"."6677ad57-ece4-448e-b9ca-d81d7ab98c13"."minsizerule" = 2;
      "kwinrulesrc"."6677ad57-ece4-448e-b9ca-d81d7ab98c13"."wmclass" =
        "^(?!.*krunner).*$";
      "kwinrulesrc"."6677ad57-ece4-448e-b9ca-d81d7ab98c13"."wmclassmatch" = 3;
      "kwinrulesrc"."8d871eef-ccfb-4eb3-bdf4-d1bc2e214583"."Description" =
        "force border";
      "kwinrulesrc"."8d871eef-ccfb-4eb3-bdf4-d1bc2e214583"."noborderrule" = 2;
      "kwinrulesrc"."General"."count" = 3;
      "kwinrulesrc"."General"."rules" = "1,2,3";
      "kwinrulesrc"."a1e5baaf-872a-4004-bdc3-1f209d95daef"."Description" =
        "force border";
      "kwinrulesrc"."a1e5baaf-872a-4004-bdc3-1f209d95daef"."noborderrule" = 2;
      "kwinrulesrc"."bd2b5543-c640-4aa9-8d5a-f746f059919f"."Description" = "sa";
      "kwinrulesrc"."bd2b5543-c640-4aa9-8d5a-f746f059919f"."noborder" = true;
      "kwinrulesrc"."bd2b5543-c640-4aa9-8d5a-f746f059919f"."noborderrule" = 2;
      "kxkbrc"."Layout"."DisplayNames" = "";
      "kxkbrc"."Layout"."LayoutList" = "us";
      "kxkbrc"."Layout"."Options" = "terminate:ctrl_alt_bksp,caps:swapescape";
      "kxkbrc"."Layout"."ResetOldOptions" = true;
      "kxkbrc"."Layout"."Use" = true;
      "kxkbrc"."Layout"."VariantList" = "";
      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
      "plasmanotifyrc"."Notifications"."PopupPosition" = "TopRight";
      "plasmarc"."Wallpapers"."usersWallpapers" = "";
      "systemsettingsrc"."KFileDialog Settings"."detailViewIconSize" = 16;
    };
  };
}

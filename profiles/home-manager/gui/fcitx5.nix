{ pkgs, ... }: {
  # https://github.com/fkxxyz/rime-cloverpinyin/wiki/linux#%E5%88%87%E6%8D%A2%E5%88%B0%E8%AF%A5%E8%BE%93%E5%85%A5%E6%96%B9%E6%A1%88
  xdg.dataFile = {
    "fcitx5/rime/default.custom.yaml".source =
      (pkgs.formats.yaml { }).generate "default.custom" {
        patch = {
          "menu/page_size" = 5;
          schema_list = [{ schema = "clover"; }];
          "ascii_composer/good_old_caps_lock" = true;
          "ascii_composer/switch_key" = {
            "Caps_Lock" = "noop";
            "Shift_L" = "commit_code";
            "Shift_R" = "commit_code";
            "Control_L" = "noop";
            "Control_R" = "noop";
          };
          "switcher/hotkeys" = [ "F4" ];
        };
      };
  };

  home.file.".config/fcitx5/config".text = ''
    [Hotkey]
    # Enumerate when press trigger key repeatedly
    EnumerateWithTriggerKeys=True
    # Skip first input method while enumerating
    EnumerateSkipFirst=False

    [Hotkey/TriggerKeys]
    0=Super+space
    1=Zenkaku_Hankaku
    2=Hangul

    [Hotkey/AltTriggerKeys]
    0=Shift_L

    [Hotkey/EnumerateForwardKeys]
    0=Control+BackSpace

    [Hotkey/EnumerateBackwardKeys]
    0=Control+Shift_R

    [Hotkey/EnumerateGroupForwardKeys]
    0=Super+space

    [Hotkey/EnumerateGroupBackwardKeys]
    0=Shift+Super+space

    [Hotkey/ActivateKeys]
    0=Hangul_Hanja

    [Hotkey/DeactivateKeys]
    0=Hangul_Romaja

    [Hotkey/PrevPage]
    0=Up

    [Hotkey/NextPage]
    0=Down

    [Hotkey/PrevCandidate]
    0=Shift+Tab

    [Hotkey/NextCandidate]
    0=Tab

    [Hotkey/TogglePreedit]
    0=Control+Alt+P

    [Behavior]
    # Active By Default
    ActiveByDefault=False
    # Share Input State
    ShareInputState=No
    # Show preedit in application
    PreeditEnabledByDefault=True
    # Show Input Method Information when switch input method
    ShowInputMethodInformation=True
    # Show Input Method Information when changing focus
    showInputMethodInformationWhenFocusIn=False
    # Show compact input method information
    CompactInputMethodInformation=True
    # Show first input method information
    ShowFirstInputMethodInformation=True
    # Default page size
    DefaultPageSize=5
    # Override Xkb Option
    OverrideXkbOption=False
    # Custom Xkb Option
    CustomXkbOption=
    # Force Enabled Addons
    EnabledAddons=
    # Force Disabled Addons
    DisabledAddons=
    # Preload input method to be used by default
    PreloadInputMethod=True
  '';

  # @see https://github.com/catppuccin/fcitx5#enabling-manually
  home.file.".config/fcitx5/conf/classicui.conf".text = ''
    # Vertical Candidate List
    Vertical Candidate List=False
    # Use Per Screen DPI
    PerScreenDPI=True
    # Use mouse wheel to go to prev or next page
    WheelForPaging=True
    # Font
    Font="Sans 10"
    # Menu Font
    MenuFont="Sans 10"
    # Tray Font
    TrayFont="Sans Bold 10"
    # Tray Label Outline Color
    TrayOutlineColor=#000000
    # Tray Label Text Color
    TrayTextColor=#ffffff
    # Prefer Text Icon
    PreferTextIcon=False
    # Show Layout Name In Icon
    ShowLayoutNameInIcon=True
    # Use input method language to display text
    UseInputMethodLangaugeToDisplayText=True
    # Theme or macchiato, frappe, latte, mocha
    Theme=catppuccin-mocha
    # Force font DPI on Wayland
    ForceWaylandDPI=0
  '';
}

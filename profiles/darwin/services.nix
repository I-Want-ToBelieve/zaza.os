{...}: {
  services = {
    karabiner-elements = {
      enable = true;
    };

    skhd = {
      enable = true;
      skhdConfig = ''
        alt + shift - r   :   chunkc quit
      '';
    };

    yabai = {
      enable = true;
      enableScriptingAddition = true;
      config = {
        focus_follows_mouse = "off";
        mouse_follows_focus = "off";
        window_placement = "second_child";
        window_opacity = 0.90;
        top_padding = 10;
        bottom_padding = 10;
        left_padding = 10;
        right_padding = 10;
        window_gap = 10;
      };
      extraConfig = ''
        yabai -m rule --add app='System Preferences' manage=off
        borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0 2>/dev/null 1>&2 &
      '';
    };
  };
}

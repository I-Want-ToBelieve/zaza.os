{...}: {
  services = {
    karabiner-elements = {
      enable = true;
    };

    skhd = {
      enable = true;
      skhdConfig = ''
        ctrl - return : kitty --single-instance -d ~
        # https://github.com/koekeishiya/skhd/blob/f88e7ad403ebbee1b8bac988d8b162d595f595c4/src/tokenize.h#L16
        cmd - delete : skhd -k "ctrl - space"
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
        top_padding = 20;
        bottom_padding = 20;
        left_padding = 20;
        right_padding = 20;
        window_gap = 20;
      };
      extraConfig = ''
        borders active_color=0xff6eff89 inactive_color=0xff516468 width=12.0 2>/dev/null 1>&2 &

        yabai -m rule --add app='System Preferences' manage=off

        yabai -m signal --add event=window_created action='ymsp window-created'

        yabai -m signal --add event=application_launched action='ymsp window-created'

        yabai -m signal --add event=window_moved action='ymsp window-moved'

        ymsp on-yabai-start
      '';
    };
  };
}

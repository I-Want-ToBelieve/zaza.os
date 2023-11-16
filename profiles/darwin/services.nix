{...}: let
  yakite = "/Users/i.want.to.believe/git.workspaces/js.workspaces/krohnkite-core/apps/yakite/target/release/yakite";
in {
  services = {
    karabiner-elements = {
      enable = true;
    };

    skhd = {
      enable = true;
      skhdConfig = ''
        ctrl - return : kitty --single-instance -d ~

        cmd - backspace : skhd -k "ctrl - space"

        ctrl - w : skhd -k "ctrl - up"

        ctrl - 1 : yabai -m space --focus 1
        ctrl - 2 : yabai -m space --focus 2
        ctrl - 3 : yabai -m space --focus 3
        ctrl - 4 : yabai -m space --focus 4
        ctrl - 5 : yabai -m space --focus 5
        ctrl - 6 : yabai -m space --focus 6
        ctrl - 7 : yabai -m space --focus 7
        ctrl - 8 : yabai -m space --focus 8
        ctrl - 9 : yabai -m space --focus 9
        ctrl - 0 : yabai -m space --focus 10

        ctrl - t : ${yakite} action toggle-tile-layout
        ctrl - m : ${yakite} action toggle-monocle-layout
        ctrl - f : ${yakite} action toggle-active-window-floating
        ctrl - k : ${yakite} action focus-next-window
        ctrl - i : ${yakite} action focus-previous-window
        ctrl + shift - k : ${yakite} action move-active-window-to-next-position
        ctrl + shift - i : ${yakite} action move-active-window-to-previous-position
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
      '';
    };
  };
}

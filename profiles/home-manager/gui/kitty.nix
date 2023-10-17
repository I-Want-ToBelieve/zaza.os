{ config, pkgs, lib, ... }: {
  programs.kitty = {
    enable = true;
    settings = {
      # Window
      background_opacity = lib.mkForce "0.9";
      inactive_text_alpha = "1.0";
      window_padding_width = "12 24 0 24";
      placement_strategy = "center";
      resize_in_steps = "yes";
      enabled_layouts = "*";
      remember_window_size = "no";
      initial_window_width = "640";
      initial_window_height = "400";
      confirm_os_window_close = "0";
      allow_remote_control = "yes";

      # URLs
      url_style = "double";
      copy_on_select = "yes";

      # Selection
      select_by_word_characters = ":@-./_~?&=%+#";

      # Mouse
      click_interval = "0.5";
      mouse_hide_wait = "0";
      focus_follows_mouse = "no";

      # Bell
      visual_bell_duration = "0.0";
      enable_audio_bell = "no";

      # Scroolback
      scrollback_lines = "10000";
      wheel_scroll_multiplier = "5.0";
      touch_scroll_multiplier = "1.0";

      # Cursor
      cursor_shape = "underline";
      cursor_beam_thickness = "1.2";
      cursor_underline_thickness = "2.0";
      cursor_blink_interval = "-1.0";
      cursor_stop_blinking_after = "5.0";

      # Font
      font_family = "monospace";
      italic_font = "auto";
      bold_font = "auto";
      bold_italic_font = "auto";
      font_size = "16.0";
      disable_ligatures = "never";
      adjust_line_height = "0";
      adjust_column_width = "0";
      box_drawing_scale = "0.001, 1, 1.5, 2";
    };

    extraConfig = lib.mkAfter ''
      # Tab bar
      tab_bar_style fade
      bell_on_tab yes
      tab_bar_edge bottom
      tab_title_template {index}: {title}

      active_tab_background #5f9373
      active_tab_font_style bold-italic

      inactive_tab_foreground #444
      inactive_tab_background #999
      inactive_tab_font_style bold
    '';

    # Keys
    keybindings = {
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+s" = "paste_from_selection";
      "ctrl+shift+c" = "copy_to_clipboard";
      "shift+insert" = "paste_from_selection";

      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+k" = "scroll_line_up";
      "ctrl+shift+j" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+h" = "show_scrollback";

      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      "ctrl+shift+f" = "move_window_forward";
      "ctrl+shift+b" = "move_window_backward";
      "ctrl+shift+`" = "move_window_to_top";
      "ctrl+shift+1" = "first_window";
      "ctrl+shift+2" = "second_window";
      "ctrl+shift+3" = "third_window";
      "ctrl+shift+4" = "fourth_window";
      "ctrl+shift+5" = "fifth_window";
      "ctrl+shift+6" = "sixth_window";
      "ctrl+shift+7" = "seventh_window";
      "ctrl+shift+8" = "eighth_window";
      "ctrl+shift+9" = "ninth_window";
      "ctrl+shift+0" = "tenth_window";

      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";
      "ctrl+shift+alt+t" = "set_tab_title";

      "ctrl+shift+equal" = "increase_font_size";
      "ctrl+shift+minus" = "decrease_font_size";
      "ctrl+shift+backspace" = "restore_font_size";
    };
  };
}

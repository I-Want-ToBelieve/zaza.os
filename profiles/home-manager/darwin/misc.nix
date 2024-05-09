{...}: {
  home.file.".phoenix.js".source = ./phoenix.js;

  home.file.".hammerspoon/init.lua".source = ./hammerspoon.lua;

  home.file.".proxychains/proxychains.conf".text = ''
    [ProxyList]
    socks5  127.0.0.1 20170
    http    127.0.0.1 20171
  '';

  programs.kitty = {
    # Keys
    keybindings = {
      "cmd+shift+v" = "paste_from_clipboard";
      "cmd+shift+s" = "paste_from_selection";
      "cmd+shift+c" = "copy_to_clipboard";
      "shift+insert" = "paste_from_selection";

      "cmd+shift+up" = "scroll_line_up";
      "cmd+shift+down" = "scroll_line_down";
      "cmd+shift+k" = "scroll_line_up";
      "cmd+shift+j" = "scroll_line_down";
      "cmd+shift+page_up" = "scroll_page_up";
      "cmd+shift+page_down" = "scroll_page_down";
      "cmd+shift+home" = "scroll_home";
      "cmd+shift+end" = "scroll_end";
      "cmd+shift+h" = "show_scrollback";

      "cmd+shift+enter" = "new_window";
      "cmd+shift+n" = "new_os_window";
      "cmd+shift+w" = "close_window";
      "cmd+shift+]" = "next_window";
      "cmd+shift+[" = "previous_window";
      "cmd+shift+f" = "move_window_forward";
      "cmd+shift+b" = "move_window_backward";
      "cmd+shift+`" = "move_window_to_top";
      "cmd+shift+1" = "first_window";
      "cmd+shift+2" = "second_window";
      "cmd+shift+3" = "third_window";
      "cmd+shift+4" = "fourth_window";
      "cmd+shift+5" = "fifth_window";
      "cmd+shift+6" = "sixth_window";
      "cmd+shift+7" = "seventh_window";
      "cmd+shift+8" = "eighth_window";
      "cmd+shift+9" = "ninth_window";
      "cmd+shift+0" = "tenth_window";

      "cmd+shift+right" = "next_tab";
      "cmd+shift+left" = "previous_tab";
      "cmd+shift+t" = "new_tab";
      "cmd+shift+q" = "close_tab";
      "cmd+shift+l" = "next_layout";
      "cmd+shift+." = "move_tab_forward";
      "cmd+shift+," = "move_tab_backward";
      "cmd+shift+alt+t" = "set_tab_title";

      "cmd+shift+equal" = "increase_font_size";
      "cmd+shift+minus" = "decrease_font_size";
      "cmd+shift+backspace" = "restore_font_size";
    };
  };
}

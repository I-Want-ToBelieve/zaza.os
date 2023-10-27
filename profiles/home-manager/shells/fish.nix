{pkgs, ...}: {
  programs.fish = {
    enable = true;
    # 你好，这是Bing。以下是fish shell中判断环境变量AAA为1且环境变量BBB存在且不为空时设置环境变量CCC为环境变量BBB的值的命令：
    # if test "$AAA" = "1" -a -n "$BBB"
    #     set -x CCC $BBB
    # end
    # 其中，test命令用于测试条件是否成立，-a表示逻辑与，-n表示非空。如果条件成立，则使用set命令设置环境变量CCC的值为环境变量BBB的值。
    # 希望这能帮到你！
    shellInit = ''
      if test "$KITTY_DISABLE_WAYLAND" = "1" -a -n "$WAYLAND_DISPLAY_OLD"
          set -x WAYLAND_DISPLAY $WAYLAND_DISPLAY_OLD
      end
    '';
    interactiveShellInit = ''
      # @see https://fishshell.com/docs/current/interactive.html#vi-mode-commands
      fish_vi_key_bindings
      # Emulates vim's cursor shape behavior
      # Set the normal and visual mode cursors to a block
      set fish_cursor_default block
      # Set the insert mode cursor to a line
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
      # The following variable can be used to configure cursor shape in
      # visual mode, but due to fish_cursor_default, is redundant here
      set fish_cursor_visual block
      # @see https://github.com/yannjor/krabby
      krabby random;echo -e "\033[37m\033[0m";
      bind --erase \ct
    '';
    shellAliases = {
      ls = "eza --sort type";
      l = "ls -la";
      lt = "ls --tree";
      ra = "joshuto";
      jo = "joshuto";
    };
    functions = {
      c = {
        description = "@see https://stackoverflow.com/a/34221866/11791657";
        argumentNames = "path_string";
        body = ''
          if test -n "$path_string"
            code $path_string
          else
            code .
          end
        '';
      };
    };
    plugins = with pkgs; [
      # {
      #   name = "replay.fish";
      #   src = fetchFromGitHub {
      #     owner = "jorgebucaran";
      #     repo = "replay.fish";
      #     rev = "main";
      #     sha256 = "bM6+oAd/HXaVgpJMut8bwqO54Le33hwO9qet9paK1kY=";
      #   };
      # }
    ];
  };
}

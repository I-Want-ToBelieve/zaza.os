{pkgs, ...}: {
  programs.fish = {
    enable = true;
    shellInit = ''
      if test "$KITTY_DISABLE_WAYLAND" = "1" -a -n "$WAYLAND_DISPLAY_OLD"
          set -x WAYLAND_DISPLAY $WAYLAND_DISPLAY_OLD
      end

      # path
      set -gx PATH $HOME/.cargo/bin $PATH
      set -gx PATH $HOME/.npm/bin $PATH
      set -gx PATH $HOME/.local/bin $PATH
      set -gx PATH $HOME/.yarn/bin $PATH
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
      ra = "yazi";
      proxy = "proxychains4";
      g = "git";
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

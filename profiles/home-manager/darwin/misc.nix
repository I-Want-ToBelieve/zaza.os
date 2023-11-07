{...}: {
  home.file.".phoenix.js".source = ./phoenix.js;

  home.file.".hammerspoon/init.lua".source = ./hammerspoon.lua;

  home.file.".config/ymsp/ymsp.config.json".source = ./ymsp.config.json;

  programs.kitty = {
    # Keys
    keybindings = {
    };
  };
}

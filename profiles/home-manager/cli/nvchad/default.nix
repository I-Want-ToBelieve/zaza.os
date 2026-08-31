_: {
  programs.nvchad = {
    enable = true;
    hm-activation = true;
    backup = true;
    extraConfig = builtins.readFile ./config.lua;
  };
}

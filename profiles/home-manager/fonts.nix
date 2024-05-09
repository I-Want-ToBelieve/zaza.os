{ pkgs, ... }: {
  fonts = { fontconfig = { enable = true; }; };

  home.packages = with pkgs; [ dejavu_fonts ];
}

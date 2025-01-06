{pkgs, ...}: {
  stylix.enable = true;
  # https://danth.github.io/stylix/configuration.html
  stylix.image = pkgs.fetchurl rec {
    name = "wallpaper-${sha256}.png";
    url = "https://raw.githubusercontent.com/I-Want-ToBelieve/wallpapers/main/catppuccin/cat_leaves.png";
    sha256 = "1894y61nx3p970qzxmqjvslaalbl2skj5sgzvk38xd4qmlmi9s4i";
  };

  # stylix.polarity = "dark";

  # @see https://github.com/tinted-theming/base16-schemes
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

  stylix.fonts = {
    serif = {
      package = pkgs.noto-fonts;
      name = "Noto Sans Mono";
    };

    sansSerif = {
      package = pkgs.lxgw-wenkai;
      name = "LXGW WenKai Mono";
    };

    monospace = {
      package = pkgs.nerd-fonts.inconsolata;
      name = "Inconsolata Nerd Font Mono";
    };

    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };
}

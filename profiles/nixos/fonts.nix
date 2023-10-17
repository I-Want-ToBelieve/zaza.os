{ pkgs, lib, ... }: {
  fonts = {
    packages = lib.attrValues {
      inherit (pkgs)
        emacs-all-the-icons-fonts inter material-icons material-design-icons
        noto-fonts noto-fonts-cjk noto-fonts-emoji dejavu_fonts
        twemoji-color-font wqy_microhei lxgw-wenkai wqy_zenhei;
      inherit (pkgs.inur) ttf-ubuntu-mono-ligaturized;
    };

    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        autohint = true;
        style = "full";
      };

      subpixel.lcdfilter = "default";

      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "Liga SFMono Nerd Font" ];
        sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
        serif = [ "Noto Serif" "Noto Color Emoji" ];
      };
    };
  };
}

{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [ uosc ] ++ (with pkgs; [ mpv-iptvplus ]);
    config = { osd-font-size = 25; };
  };
}

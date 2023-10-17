{ config, pkgs, ... }: {
  home.packages = with pkgs; with inur; [ ];

  services.swhkd = {
    enable = true;
    keybindings = {
      "shift + BackSpace" = "ydotool key Delete";
      "super + Return" = "kitty";
      "F1" = "flameshot gui";
      "ctrl + t" = ''
        WAYLAND_DISPLAY=no KITTY_DISABLE_WAYLAND=1 tdrop -n tdrop_terminl --post-create-hook "autohide-tdrop &" -mta -h 66% -w 70% -x 15% -y 0 kitty --class tdrop_terminl'';
      "ctrl + g" = "copyq toggle";
      "super + Escape" = "pkill -USR1 -x swhkd";
    };
  };
}

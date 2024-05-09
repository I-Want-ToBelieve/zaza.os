{pkgs, ...}: {
  home.packages = with pkgs; with inur; [xdotool];

  services.sxhkd = {
    enable = false;
    keybindings = {
      "shift + BackSpace" = "xdotool key Delete";
      "super + Return" = "kitty";
      "F1" = "flameshot gui";
      "ctrl + t" = ''
        tdrop -n tdrop_terminal --post-create-hook "autohide-tdrop &" -ma -h 60% -w 70% -x 15% -y 0 kitty --class=tdrop_terminal'';
      "ctrl + j" = ''
        tdrop -n tdrop_terminal_j --post-create-hook "autohide-tdrop &" -ma -h 60% -w 70% -x 15% -y 0 kitty --class=tdrop_terminal_j'';
      "ctrl + grave" = "toggle-vscode-terminal";
      "ctrl + g" = "copyq toggle";
      "super + Escape" = "pkill -USR1 -x sxhkd";
    };
  };
}

_: {
  # https://danth.github.io/stylix/configuration.html
  # https://danth.github.io/stylix/options/hm.html
  stylix = {
    enable = true;
    targets = {
      vscode.enable = false;
      waybar.enable = false;
      swaylock.enable = false;
      vim.enable = false;
      # 下面四个已经没有可主题化的对象（KDE 已移除，机器上也没有 GTK/GNOME/XFCE 会话），
      # 保留只是为了在将来真装上它们时不被 stylix 意外接管。
      gtk.enable = false;
      kde.enable = false;
      xfce.enable = false;
      gnome.enable = false;
    };
  };
}

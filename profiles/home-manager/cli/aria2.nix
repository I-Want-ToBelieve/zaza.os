{
  programs.aria2 = {
    enable = true;
    settings = {
      dir = "/home/i.want.to.believe/Games/Games";

      # rpc
      enable-rpc = true;
      rpc-listen-port = 6800;
      rpc-listen-all = true;
      rpc-allow-origin-all = true;
    };
  };
}

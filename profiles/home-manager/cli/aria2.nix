{
  programs.aria2 = {
    enable = true;
    settings = {
      dir = "Downloads";

      # rpc
      enable-rpc = true;
      rpc-listen-port = 6800;
      rpc-listen-all = true;
      rpc-allow-origin-all = true;
    };
  };
}

{...}: {
  services.xserver.enable = true;
  services.displayManager = {
    defaultSession = "plasmawayland";
    autoLogin = {
      enable = true;
      user = "i.want.to.believe";
    };
    sddm = {
      enable = true;
      wayland.enable = true;

      # settings = {
      #   Autologin = {
      #     Session = "plasmawayland";
      #     User = "i.want.to.believe";
      #   };
      # };
    };
  };
}

{...}: {
  services.xserver.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      # settings = {
      #   Autologin = {
      #     Session = "plasmawayland";
      #     User = "i.want.to.believe";
      #   };
      # };
    };
  };
}

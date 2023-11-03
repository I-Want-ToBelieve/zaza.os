{pkgs, ...}: {
  # age.secrets.i.want.to.believe.file = "${self}/secrets/i.want.to.believe.age";
  programs.fish.enable = true;

  users.users."i.want.to.believe" = {
    description = "I Want To Believe";
    shell = pkgs.fish;

    home = "/Users/i.want.to.believe";
  };
}

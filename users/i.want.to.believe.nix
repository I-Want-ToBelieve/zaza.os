{pkgs, ...}: {
  # age.secrets.i.want.to.believe.file = "${self}/secrets/i.want.to.believe.age";
  programs.fish.enable = true;

  users.mutableUsers = true;

  users.users."i.want.to.believe" = {
    description = "I Want To Believe";
    shell = pkgs.fish;

    # passwordFile = config.age.secrets.i.want.to.believe.path;
  };

  isNormalUser = true;

  initialPassword = "nixos";

  createHome = true;

  # compatibility with old drives
  uid = 1000;

  extraGroups = [
    "wheel"
    "nix"
    "systemd-journal"
    "adbusers" # android bits
    "audio"
    "video"
    "dialout" # ttyACM*
    "docker"
    "libvirtd"
    "lp" # SANE
    "networkmanager"
    "piavpn"
    "render"
    "render"
    "scanner"
    "vboxusers"
    "wireshark"
    "mysql"
    "lxd" # waydroid
  ];
}

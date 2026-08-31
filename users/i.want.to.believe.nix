{pkgs, ...}: {
  # 密钥现在由 clan vars 管理，见 flake/vars.nix。
  # 这里曾经是 agenix 的引用，指向已删除的 secrets/ 目录。
  programs.fish.enable = true;

  users.mutableUsers = true;

  users.users."i.want.to.believe" = {
    description = "I Want To Believe";
    shell = pkgs.fish;

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
    # 启用 clan vars 托管的口令时，取消 flake/vars.nix 末尾那段注释，
    # 并删掉上面的 initialPassword。
  };
}

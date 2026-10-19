{
  pkgs,
  lib,
  ...
}: {
  # enable flakes globally
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  # Use this instead of services.nix-daemon.enable if you
  # don't wan't the daemon service to be managed for you.
  # nix.useDaemon = true;

  nix.package = pkgs.nix;

  # GC 保留一个月。
  #
  # 此前是 1w，而这正是本机只剩一个 generation（system-8-link）的原因 ——
  # 1 到 7 全被回收了，于是 `darwin-rebuild --rollback` 没有任何纵深可回。
  # NixOS 侧在同一轮重构里已从 7d 放宽到 90d，darwin 当时漏了。
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 30d";
  };

  nix.settings.trusted-users = ["i.want.to.believe"];

  # Manual optimise storage: nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  # nix.settings.automatic = true;

  nix.settings.substituters = lib.mkForce [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://cache.nixos.org/"
  ];
}

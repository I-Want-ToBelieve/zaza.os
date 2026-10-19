{
  pkgs,
  lib,
  ...
}: {
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix = {
    # Auto upgrade nix package and the daemon service.
    # 用 nix.enable 而不是 services.nix-daemon.enable —— 后者是旧选项名。
    enable = true;
    package = pkgs.nix;

    # 存储优化保持手动：nix-store --optimise
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store

    # GC 保留一个月。
    #
    # 此前是 1w，而这正是本机只剩一个 generation（system-8-link）的原因 ——
    # 1 到 7 全被回收了，于是 `darwin-rebuild --rollback` 没有任何纵深可回。
    # NixOS 侧在同一轮重构里已从 7d 放宽到 90d，darwin 当时漏了。
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 30d";
    };

    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["i.want.to.believe"];

      # 这是 darwin 侧唯一一处 substituters 定义。NixOS 侧的对应说明见
      # profiles/nixos/nix.nix —— listOf str 是拼接语义、mkForce 不去重，
      # 所以不要在别处再写一份。
      substituters = lib.mkForce [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
    };
  };
}

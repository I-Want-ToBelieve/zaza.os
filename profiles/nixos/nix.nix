{
  pkgs,
  lib,
  inputs,
  ...
}: {
  environment = {
    # we need git for flakes
    systemPackages = [pkgs.git];
    defaultPackages = [];
  };

  # faster rebuilding
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    dev.enable = false;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      # 曾是 7d。配合 dell-makcoo 的 grub configurationLimit = 1，这意味着教室机
      # 极可能只剩一个 generation、GRUB 里零个回滚项 —— 推坏了就只能走去教室。
      options = "--delete-older-than 90d";
    };

    # pin the registry to avoid downloading and evaling a new nixpkgs version every time
    registry.nixpkgs.flake = inputs.nixpkgs;

    # set the path for channels compat
    # nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      warn-dirty = false
      keep-derivations = true
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';

    optimise.automatic = true;

    settings = {
      # Improve nix store disk usage
      sandbox = true;
      auto-optimise-store = true;
      builders-use-substitutes = true;
      trusted-users = ["root" "@wheel"];
      allowed-users = ["@wheel"];
      max-jobs = "auto";
      flake-registry = "/etc/nix/registry.json";

      # for direnv GC roots
      keep-derivations = true;
      keep-outputs = true;

      # 二进制缓存。这是全仓库**唯一**一处 substituters 定义 —— 刻意如此。
      #
      # NixOS 的 listOf str 是拼接语义、mkForce 只定优先级不去重，所以任何
      # 第二处 mkForce 都会与这里叠加（历史上 cachix/default.nix 就有一份
      # 逐字相同的，导致三个镜像各出现两次）。要加缓存就加在这里。
      #
      # mkForce 同时丢掉了 nixpkgs 自己的 `mkAfter ["https://cache.nixos.org/"]`，
      # 所以上游缓存必须由我们显式列出 —— 它在这里，位置排在国内镜像之后。
      #
      # nix-community 的 trusted-public-keys 声明在 cachix/nix-community.nix，
      # 签名校验因此成立。它在国内可能较慢，但 clan 设了
      # nix.settings.connect-timeout = 5，连不上会很快跳过。
      substituters = lib.mkForce [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
    };
  };
}

{
  pkgs,
  lib,
  ...
}:
# nix tooling
{
  home = {
    packages = with pkgs; [alejandra deadnix statix];

    sessionVariables = {DIRENV_LOG_FORMAT = "";};
  };

  nix.settings = {
    trusted-users = ["root" "@wheel" "@admin"];
    allowed-users = ["@wheel" "@admin"];
    substituters = lib.mkForce [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
  };
}

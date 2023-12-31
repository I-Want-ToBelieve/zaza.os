{pkgs, ...}: {
  # https://nixos.wiki/wiki/Android#Building_Android_on_NixOS
  programs = {
    adb.enable = true;

    java = {
      enable = true;
    };
  };
}

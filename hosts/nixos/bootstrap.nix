{ profiles, lib, ... }: {
  imports = [
    # profiles.networking
    profiles.core.nixos
    profiles.users.root # make sure to configure ssh keys
    profiles.users.nixos
  ];

  boot.loader.systemd-boot.enable = true;

  # Note: This does not prevent using wireless networks, this simply disables
  # wpa_supplicant in favor of using NetworkManager and associated CLI tools
  networking.wireless.enable = lib.mkForce false;

  # Required, but will be overridden in the resulting installer ISO.
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; };
}

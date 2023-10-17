{ pkgs, config, lib, ... }: {
  imports = [ ];

  hardware = {
    opengl = { enable = true; };

    bluetooth = {
      enable = true;
      package = pkgs.bluez;
    };

    enableRedistributableFirmware = true;
    pulseaudio.enable = false;
  };

  boot = {
    kernelModules = [ ];
    extraModprobeConfig = "";
    extraModulePackages = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];

    supportedFilesystems = [ "btrfs" ];

    initrd = {
      availableKernelModules =
        [ "xhci_pci" "ehci_pci" "ahci" "nvme_core" "nvme" "usb_storage" ]
        ++ config.boot.initrd.luks.cryptoModules;
      kernelModules = [ "dm-snapshot" ];
      luks.devices.luksroot = {
        device = "/dev/disk/by-label/cryptroot";
        preLVM = true;
        allowDiscards = true;
      };
    };

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      systemd-boot.enable = false;

      grub = {
        enable = true;
        version = 2;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        enableCryptodisk = true;
        configurationLimit = 5;
      };
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options =
      [ "subvol=root" "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options =
      [ "subvol=home" "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  # compresses half the ram for use as swap
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  virtualisation = {
    spiceUSBRedirection.enable = true;
    vmware = { guest = { enable = true; }; };
  };

  services = {
    btrfs.autoScrub.enable = true;
    acpid.enable = true;
    thermald.enable = true;
    upower.enable = true;

    tlp = {
      enable = false;
      settings = {
        START_CHARGE_THRESH_BAT0 = 0;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # xserver.videoDrivers = ["amdgpu"];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment = {
    systemPackages = with pkgs; [
      acpi
      brightnessctl
      libva-utils
      ocl-icd
      qt5.qtwayland
      qt5ct
    ];
  };
}

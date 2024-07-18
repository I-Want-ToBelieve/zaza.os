{
  inputs,
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}: let
  # Generated with
  #
  # nix shell .#rkvm --command "rkvm-certificate-gen --ip-addresses 192.168.0.xxx cert.pem key.pem"
  #
  snakeoil-cert = ../../assets/pems/cert.pem;
  snakeoil-key = ../../assets/pems/key.pem;
in {
  imports =
    [(modulesPath + "/installer/scan/not-detected.nix")]
    ++ [
      inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
      inputs.nixos-hardware.nixosModules.common-gpu-intel
    ];

  services.rkvm = {
    client = {
      enable = true;
      settings = {
        password = "0123456789";
        server = "192.168.0.130:5258";
        certificate = snakeoil-cert;
        key = snakeoil-key;
      };
    };
  };

  system.stateVersion = lib.mkForce "24.05";

  users.groups.input.members = ["i.want.to.believe"];

  services.udev.extraRules = ''
    # Sunshine
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  services.sunshine.enable = false;

  # amd gpu
  boot.blacklistedKernelModules = ["nouveau" "nvidia"];
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.hip-common}"
    "f /dev/shm/looking-glass 0660 i.want.to.believe qemu-libvirtd -"
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
  };

  hardware = {
    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    steam-hardware = {enable = true;};

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {General = {Experimental = true;};};
    };

    # @see https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/12
    i2c = {enable = true;};

    enableRedistributableFirmware = true;
    pulseaudio.enable = false;
  };

  # services.xserver.videoDrivers = ["amdgpu"];

  boot = {
    kernelModules = [
      "kvm-intel" # If using an AMD CPU, use `kvm-amd`
      # https://www.reddit.com/r/NixOS/comments/p8bqvu/how_to_install_v4l2looback_kernel_module/?onetap_auto=true
      # Virtual Camera
      "v4l2loopback"
      # Virtual Microphone, built-in
      "snd-aloop"
    ];
    extraModprobeConfig = ''
      # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
      # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
      # https://github.com/umlaeute/v4l2loopback
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label="Virtual Camera"
    '';
    extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "i915.enable_psr=0"
      # "i915.enable_gvt=1"
      # "i915.enable_guc=0"
      # "iommu=pt"
      # "earlymodules=vfio-pci"
      # "vfio-pci.ids=8086:1912"
      # "pcie_aspm=off"
    ];

    supportedFilesystems = ["btrfs" "ntfs"];

    initrd = {
      availableKernelModules =
        ["xhci_pci" "ehci_pci" "ahci" "nvme_core" "nvme" "usb_storage"]
        ++ config.boot.initrd.luks.cryptoModules;
      kernelModules =
        ["dm-snapshot"]
        ++
        # @see https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
        # @see https://viniciusmuller.github.io/blog/NixOS/gpu_passthrough.html#identifying-iommu-devices
        # @see https://nixos.wiki/wiki/IGVT-g
        [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
          # "vfio-mdev"
          # "vfio_virqfd"
        ];
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
    options = ["subvol=root" "compress=zstd" "noatime" "ssd" "space_cache=v2"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = ["subvol=home" "compress=zstd" "noatime" "ssd" "space_cache=v2"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = ["subvol=nix" "compress=zstd" "noatime" "ssd" "space_cache=v2"];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = ["subvol=log" "compress=zstd" "noatime" "ssd" "space_cache=v2"];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [{device = "/dev/disk/by-label/swap";}];

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

    waydroid.enable = true;
    lxd.enable = true;

    docker = {
      enable = true;
      daemon = {
        settings = {
          registry-mirrors = ["https://registry.docker-cn.com" "https://hub-mirror.c.163.com"];
        };
      };
    };

    podman = {
      enable = true;
      extraPackages = with pkgs; [skopeo conmon runc];
    };

    libvirtd = {
      enable = true;
      qemu = {
        ovmf = {enable = true;};
        runAsRoot = false;
      };
    };
  };

  systemd.enableUnifiedCgroupHierarchy = lib.mkForce true;

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
  };

  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  environment = {
    variables = {
      AMD_VULKAN_ICD = "RADV";
      DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 = "1";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
      QT_LOGGING_RULES = "kwin_*.debug=true";
      GTK_CSD = "0";
    };

    sessionVariables = {
      # NIXOS_OZONE_WL = "1";
      LIBVA_DRIVER_NAME = "iHD"; # Force intel-media-driver
    };

    systemPackages = with pkgs; [
      acpi
      brightnessctl
      docker-client
      docker-compose
      docker-credential-helpers
      libva-utils
      ocl-icd
      qt5.qtwayland
      qt5ct
      virt-manager
      virt-viewer
      vulkan-tools
      vulkan-loader
      wl-clipboard
      ydotool
      vkbasalt
      vkbasalt-cli
      # inur.systemd-shutdown-diagnose
    ];
  };
}

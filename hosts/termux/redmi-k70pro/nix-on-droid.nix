{
  config,
  lib,
  pkgs,
  ...
}: {
  # Simply install just the packages
  environment.packages = with pkgs; [
    # User-facing stuff that you really really want to have
    neovim # or some other editor, e.g. nano or neovim

    iproute2

    git

    # Some common stuff that people expect to have
    procps
    killall
    diffutils
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip
    unzip
  ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone
  #time.timeZone = "Europe/Berlin";

  # Configure home-manager
  home-manager = {
    config = ./home.nix;
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
  };

  users.users.nix-on-droid = {
    shell = pkgs.fish;
    initialPassword = lib.mkForce "nixos";
    openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCRJ0EFYpSiXT9S6J22i1RnlaYehpHf8TtU7vp8ho3dse4hw8H8y0LcFscWkaKgjDrXTHZq2S553+2ve4cGoJuCBv2Kka4VqIw62yOShOPuZP/wTfRoXlAcF8XLcHWoVDv8quzLxF+lNP6DkJFUf4/rApFs0wIIOwfgSxU5p9AIR2h02M14hEeQcva8M7R3/fK6uQInkqICLnZYljYGozTmzG2HScasIXZ7qnrPLWDn3SrWvEMBkgtKt26/ivkPR7yiN56o1BUaiR9eP25JSKGT+XkoDBAkh6UFnfw6OvQ2sFcxJHInyZUqmZRM6opM2vnlucpG8A3dCU7s5C8YTQrhVL1iHFGp/v7k4RMQbR8jOBX+wCDSsiV6kMkV1EEKaAdYEvNhREXVIL2tem2IKq/Ix269hoTeVA8Bv+I7/0FChompnklCrDrBjHB0/9BeYWnKNRGVwTetIQq4dYQ9UpCkeC8SsBEeyOCfQGnvtaHU3mgxju1lSC+71fQG2eOfEkU= thinkpad-t420s-root"];
  };
}

{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) fileContents;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  # Sets binary caches which speeds up some builds
  imports = [../cachix];

  environment = {
    # Selection of sysadmin tools that can come in handy
    systemPackages = with pkgs; [
      binutils
      coreutils
      curl
      direnv
      dnsutils
      fd
      git
      bottom
      jq
      manix
      moreutils
      nix-index
      nmap
      ripgrep
      skim
      tealdeer
      whois
    ];

    # Starship is a fast and featureful shell prompt
    # starship.toml has sane defaults that can be changed there
    shellInit = "\n";

    shellAliases = let
      # The `security.sudo.enable` option does not exist on darwin because
      # sudo is always available.
      ifSudo = lib.mkIf (isDarwin || config.security.sudo.enable);
    in {
      # quick cd
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      # git
      g = "git";

      # grep
      grep = "rg";
      gi = "grep -i";

      # internet ip
      # TODO: explain this hard-coded IP address
      myip = "dig +short myip.opendns.com @208.67.222.222 2>&1";

      # nix
      n = "nix";
      np = "n profile";
      ni = "np install";
      nr = "np remove";
      ns = "n search --no-update-lock-file";
      nf = "n flake";
      nepl = "n repl '<nixpkgs>'";
      srch = "ns nixos";
      orch = "ns override";
      mn = ''
        manix "" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | sk --preview="manix '{}'" | xargs manix
      '';
      top = "btm";

      # sudo
      s = ifSudo "sudo -E ";
      si = ifSudo "sudo -i";
      se = ifSudo "sudoedit";
    };
  };

  fonts.packages = with pkgs; [powerline-fonts dejavu_fonts];

  nix = {
    # Improve nix store disk usage
    gc.automatic = true;
    sshServe = {
      enable = true;
      keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCRJ0EFYpSiXT9S6J22i1RnlaYehpHf8TtU7vp8ho3dse4hw8H8y0LcFscWkaKgjDrXTHZq2S553+2ve4cGoJuCBv2Kka4VqIw62yOShOPuZP/wTfRoXlAcF8XLcHWoVDv8quzLxF+lNP6DkJFUf4/rApFs0wIIOwfgSxU5p9AIR2h02M14hEeQcva8M7R3/fK6uQInkqICLnZYljYGozTmzG2HScasIXZ7qnrPLWDn3SrWvEMBkgtKt26/ivkPR7yiN56o1BUaiR9eP25JSKGT+XkoDBAkh6UFnfw6OvQ2sFcxJHInyZUqmZRM6opM2vnlucpG8A3dCU7s5C8YTQrhVL1iHFGp/v7k4RMQbR8jOBX+wCDSsiV6kMkV1EEKaAdYEvNhREXVIL2tem2IKq/Ix269hoTeVA8Bv+I7/0FChompnklCrDrBjHB0/9BeYWnKNRGVwTetIQq4dYQ9UpCkeC8SsBEeyOCfQGnvtaHU3mgxju1lSC+71fQG2eOfEkU= thinkpad-t420s-root"];
    };

    # Generally useful nix option defaults
    extraOptions = ''
      min-free = 536870912
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';
  };
}

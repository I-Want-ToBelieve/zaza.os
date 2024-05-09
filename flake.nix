{
  description = "ZazaOS";

  outputs = inputs @ {
    self,
    flake-parts,
    nixpkgs,
    haumea,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({moduleWithSystem, ...}: {
      imports = [inputs.devenv.flakeModule];

      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin"];

      debug = true;

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # packages = import ./pkgs {inherit pkgs;};
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        devenv.shells.default = {
          name = "zaza.os's devenv";

          imports = [
            # This is just like the imports in devenv.nix.
            # See https://devenv.sh/guides/using-with-flake-parts/#import-a-devenv-module
            # ./devenv-foo.nix
          ];

          # https://devenv.sh/reference/options/
          packages = with pkgs; [nvfetcher];

          # https://devenv.sh/basics/
          env = {GREET = "🛠️ Let's hack 🧑🏻‍💻";};

          # https://devenv.sh/scripts/
          scripts.hello.exec = "echo $GREET";
          scripts.rebuild.exec = "nix run nix-darwin --accept-flake-config -- switch --flake .#k99-lite-darwin";

          enterShell = ''
            hello
          '';

          # https://devenv.sh/languages/
          languages.nix = {enable = true;};

          # Make diffs fantastic
          difftastic.enable = true;

          # https://devenv.sh/pre-commit-hooks/
          pre-commit.hooks = {
            alejandra.enable = true;
            editorconfig-checker.enable = true;
          };

          # Plugin configuration
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

        modules = {
          nixos = haumea.lib.load {
            src = ./modules/nixos;
            loader = haumea.lib.loaders.path;
          };
          home-manager = haumea.lib.load {
            src = ./modules/home-manager;
            loader = haumea.lib.loaders.path;
          };
        };

        nixosModules = builtins.listToAttrs (builtins.map (k: {
          name = k;
          value = import self.modules.nixos.${k};
        }) (builtins.attrNames self.modules.nixos));

        homeManagerModules = builtins.listToAttrs (builtins.map (k: {
          name = k;
          value = import self.modules.home-manager.${k};
        }) (builtins.attrNames self.modules.home-manager));

        profiles = {
          nixos = haumea.lib.load {
            src = ./profiles/nixos;
            loader = haumea.lib.loaders.path;
          };
          home-manager = haumea.lib.load {
            src = ./profiles/home-manager;
            loader = haumea.lib.loaders.path;
          };
          darwin = haumea.lib.load {
            src = ./profiles/darwin;
            loader = haumea.lib.loaders.path;
          };
        };

        suites = {
          nixos = with self.profiles.nixos; {
            base = [core.nixos];
            kde-x11 = [display-managers.sddm desktop-environment.kde];
            kde-wayland = [display-managers.sddm desktop-environment.kde];
            hyprland = [display-managers.greetd];
            misc = [
              network
              nix
              locale
              fonts
              stylix
              share-via-wifi
              samba
              rescue-boot
              development.android
            ];
            games = [game.steam game.uudeck.default];
          };
          home-manager = with self.profiles.home-manager; {
            base = [packages nix misc fonts stylix];
            cli = with cli; [direnv git ssh starship joshuto mangohud aria2];
            gui = with gui; [
              firefox.default
              fcitx5
              kitty
              obs-studio
              zathura
              copyq
              looking-glass-client
              mpv
            ];
            shells = with shells; [fish zsh nu.default];
            wsl = with wsl; [plasma];
            darwin = with darwin;
              [
                nix
                packages
                misc
              ]
              ++ [cli.git cli.direnv cli.ssh cli.starship gui.kitty shells.fish shells.zsh shells.nu.default stylix];
            hyprland = with desktop; [
              dunst
              waybar
              window-managers.hyprland
              rofi
              swaylock
              mime
            ];

            kde-x11 = [desktop.plasma desktop.bismuth desktop.kvantum];
            kde-wayland = [desktop.plasma desktop.bismuth desktop.kvantum];
          };

          darwin = with self.profiles.darwin; {
            misc = [apps nix stylix services];
          };
        };

        overlays.default = import ./overlays;

        nixosConfigurations = {
          "k99-lite" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              suites = self.suites.nixos;
              inputs = inputs;
              self = self;
            };
            modules =
              nixpkgs.lib.attrValues self.nixosModules
              ++ [
                ({
                  config,
                  pkgs,
                  ...
                }: {
                  nixpkgs.overlays = [
                    (final: prev: {
                      __dontExport = true;
                      lib = prev.lib.extend (lfinal: lprev: {our = self.lib;});
                    })
                    (final: prev: {
                      inur = inputs.inur.packages."${prev.system}";
                    })
                    (final: _: let
                      inherit (final) system;
                    in {
                      # Packages provided by flake inputs
                      crane-lib = inputs.crane.lib.${system};
                    })
                    inputs.nur.overlay
                    inputs.agenix.overlays.default
                    inputs.nvfetcher.overlays.default
                    inputs.rust-overlay.overlays.default
                    (import ./pkgs)
                    self.overlays.default
                  ];
                  nixpkgs.config = {
                    allowUnfree = true;
                    permittedInsecurePackages = [
                      "electron-13.6.9"
                      "electron-19.0.7"
                      "openssl-1.1.1v"
                      "openssl-1.1.1w"
                      "python3.11-django-3.1.14"
                    ];
                  };
                })
              ]
              ++ [
                {
                  imports = with self.suites.nixos;
                    nixpkgs.lib.flatten [base misc games kde-wayland];
                }
              ]
              ++ [
                inputs.home-manager.nixosModules.home-manager

                inputs.stylix.nixosModules.stylix
                {
                  system.stateVersion = "23.11";
                  system.autoUpgrade.enable = false;
                }

                inputs.agenix.nixosModules.default
                ./hosts/nixos/k99-lite.nix

                ./users/root.nix

                ./users/i.want.to.believe.nix

                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = {inputs = inputs;};
                  home-manager.users."i.want.to.believe" = {
                    imports =
                      nixpkgs.lib.attrValues self.homeManagerModules
                      ++ (with self.suites.home-manager;
                          nixpkgs.lib.flatten [base cli gui shells kde-wayland])
                      ++ [
                        inputs.nix-index-database.hmModules.nix-index
                        inputs.plasma-manager.homeManagerModules.plasma-manager
                        {programs.nix-index-database.comma.enable = true;}
                      ];
                    home.stateVersion = "23.11";
                  };
                  # Optionally, use home-manager.extraSpecialArgs to pass
                  # arguments to home.nix
                }
              ];
          };
          "k99-lite-wsl" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              suites = self.suites.nixos;
              inputs = inputs;
              self = self;
            };
            modules =
              [
                ({
                  config,
                  pkgs,
                  ...
                }: {
                  nixpkgs.overlays = [
                    (final: prev: {
                      __dontExport = true;
                      lib = prev.lib.extend (lfinal: lprev: {our = self.lib;});
                    })
                    (final: prev: {
                      inur = inputs.inur.packages."${prev.system}";
                    })
                    (final: _: let
                      inherit (final) system;
                    in {
                      # Packages provided by flake inputs
                      crane-lib = inputs.crane.lib.${system};
                    })
                    inputs.nur.overlay
                    inputs.agenix.overlays.default
                    inputs.nvfetcher.overlays.default
                    inputs.rust-overlay.overlays.default
                    (import ./pkgs)
                    self.overlays.default
                  ];
                  nixpkgs.config = {
                    allowUnfree = true;
                    permittedInsecurePackages = [
                      "electron-13.6.9"
                      "electron-19.0.7"
                      "openssl-1.1.1w"
                      "openssl-1.1.1v"
                      "python3.11-django-3.1.14"
                    ];
                  };
                })
              ]
              ++ [
                {
                  imports = with self.suites.nixos;
                    nixpkgs.lib.flatten [base misc kde-wayland];
                }
              ]
              ++ [
                inputs.nixos-wsl.nixosModules.wsl
                inputs.home-manager.nixosModules.home-manager

                inputs.stylix.nixosModules.stylix
                {
                  system.stateVersion = "23.11";
                  system.autoUpgrade.enable = false;
                }

                inputs.agenix.nixosModules.default
                ./hosts/wsl/k99-lite-wsl.nix

                ./users/root.nix

                ./users/i.want.to.believe.nix

                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = {inputs = inputs;};
                  home-manager.users."i.want.to.believe" = {
                    imports =
                      nixpkgs.lib.attrValues self.homeManagerModules
                      ++ (with self.suites.home-manager;
                          nixpkgs.lib.flatten [base cli gui shells kde-wayland])
                      ++ [
                        inputs.nix-index-database.hmModules.nix-index
                        inputs.plasma-manager.homeManagerModules.plasma-manager
                        {programs.nix-index-database.comma.enable = true;}
                      ];
                    home.stateVersion = "23.11";
                  };
                  # Optionally, use home-manager.extraSpecialArgs to pass
                  # arguments to home.nix
                }
              ];
          };
          "xiaoxin-pro16-2021" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              suites = self.suites.nixos;
              inputs = inputs;
              self = self;
            };
            modules =
              nixpkgs.lib.attrValues self.nixosModules
              ++ [
                ({
                  config,
                  pkgs,
                  ...
                }: {
                  nixpkgs.overlays = [
                    (final: prev: {
                      __dontExport = true;
                      lib = prev.lib.extend (lfinal: lprev: {our = self.lib;});
                    })
                    (final: prev: {
                      inur = inputs.inur.packages."${prev.system}";
                    })
                    (final: _: let
                      inherit (final) system;
                    in {
                      # Packages provided by flake inputs
                      crane-lib = inputs.crane.lib.${system};
                    })
                    inputs.nur.overlay
                    inputs.agenix.overlays.default
                    inputs.nvfetcher.overlays.default
                    inputs.rust-overlay.overlays.default
                    (import ./pkgs)
                    self.overlays.default
                  ];
                  nixpkgs.config = {
                    allowUnfree = true;
                    permittedInsecurePackages = [
                      "electron-13.6.9"
                      "electron-19.0.7"
                      "openssl-1.1.1w"
                      "openssl-1.1.1v"
                      "python3.11-django-3.1.14"
                    ];
                  };
                })
              ]
              ++ [
                {
                  imports = with self.suites.nixos;
                    nixpkgs.lib.flatten [base misc games kde-wayland];
                }
              ]
              ++ [
                inputs.home-manager.nixosModules.home-manager
                inputs.stylix.nixosModules.stylix

                {
                  system.stateVersion = "23.11";
                  system.autoUpgrade.enable = false;
                }

                inputs.agenix.nixosModules.default
                ./hosts/nixos/xiaoxin-pro16-2021.nix

                ./users/root.nix

                ./users/i.want.to.believe.nix

                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = {inputs = inputs;};
                  home-manager.users."i.want.to.believe" = {
                    imports =
                      nixpkgs.lib.attrValues self.homeManagerModules
                      ++ (with self.suites.home-manager;
                          nixpkgs.lib.flatten [base cli gui shells kde-wayland])
                      ++ [
                        inputs.nix-index-database.hmModules.nix-index
                        inputs.plasma-manager.homeManagerModules.plasma-manager
                        {programs.nix-index-database.comma.enable = true;}
                      ];
                    home.stateVersion = "23.11";
                  };
                  # Optionally, use home-manager.extraSpecialArgs to pass
                  # arguments to home.nix
                }
              ];
          };
        };
        darwinConfigurations = {
          "k99-lite-darwin" = inputs.darwin.lib.darwinSystem {
            system = "x86_64-darwin"; # change this to "aarch64-darwin" if you are using Apple Silicon
            modules =
              [
                ({
                  config,
                  pkgs,
                  ...
                }: {
                  nixpkgs.overlays = [
                    (final: prev: {
                      inur = inputs.inur.packages."${prev.system}";
                    })
                    inputs.nur.overlay

                    inputs.nvfetcher.overlays.default
                    inputs.rust-overlay.overlays.default
                    (import ./pkgs)
                    self.overlays.default
                  ];
                  nixpkgs.config = {
                    allowUnfree = true;
                    permittedInsecurePackages = [
                    ];
                  };
                })
              ]
              ++ [
                {
                  imports = with self.suites.darwin;
                    nixpkgs.lib.flatten [misc];
                }
              ]
              ++ [
                ./hosts/darwin/k99-lite-darwin.nix

                ./users/darwin/i.want.to.believe.nix
                inputs.home-manager.darwinModules.home-manager
                inputs.stylix.darwinModules.stylix
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = {inputs = inputs;};
                  home-manager.users."i.want.to.believe" = {
                    imports =
                      (with self.suites.home-manager;
                          nixpkgs.lib.flatten [darwin])
                      ++ [
                        inputs.nix-index-database.hmModules.nix-index
                        {programs.nix-index-database.comma.enable = true;}
                      ];
                    home.stateVersion = "23.11";
                  };
                }
              ];
          };
        };
      };
    });

  inputs = {
    # nixpkgs.url = "github:I-Want-ToBelieve/nixpkgs/auto-update/v2ray";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/master";

    nix2container.url = "github:nlewo/nix2container";

    nix2container.inputs = {nixpkgs.follows = "nixpkgs";};

    flake-parts.url = "github:hercules-ci/flake-parts";

    devenv.url = "github:cachix/devenv";

    haumea.url = "github:nix-community/haumea";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib.url = "github:hyprwm/contrib";
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland";

    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix.url = "github:helix-editor/helix";

    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    # my nur repository for my nixos dotfiles
    inur = {
      url = "github:I-Want-ToBelieve/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    # Stylix is a NixOS module which applies the same color scheme, font and wallpaper to a wide range of applications and desktop environments. It also exports utilities for you to use the theme in custom parts of your configuration.
    # https://danth.github.io/stylix/installation.html
    stylix.url = "github:danth/stylix";

    # @see https://github.com/nix-community/nix-index-database#usage-in-home-manager
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-gaming.url = "github:fufexan/nix-gaming";

    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-23.11-darwin";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    autohide-tdrop = {
      url = "github:I-Want-ToBelieve/autohide-tdrop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    extra-substituters = [
      "https://nix-gaming.cachix.org"
      # "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      # "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://fortuneteller2k.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://helix.cachix.org"
      "https://hyprland.cachix.org"
      "https://nrdxp.cachix.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "fortuneteller2k.cachix.org-1:kXXNkMV5yheEQwT0I4XYh1MaCSz+qg72k8XAi2PthJI="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}

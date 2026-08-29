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
      imports = [
        inputs.devenv.flakeModule
        inputs.treefmt-nix.flakeModule
        # L3 主机工厂：nixosConfigurations 与 darwinConfigurations 都由它产出
        ./flake/hosts.nix
      ];

      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

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
          packages = with pkgs; [nvfetcher] ++ [zellij] ++ [amber-lang] ++ [deno];

          # https://devenv.sh/basics/
          env = {
            GREET = "🛠️ Let's hack 🧑🏻‍💻";
            NIX_SSHOPTS = "-i /home/i.want.to.believe/.ssh/thinkpad_t420s_root_id_rsa";
          };

          # https://devenv.sh/scripts/
          scripts.hello.exec = "echo $GREET";
          scripts.rebuild.exec = "nix run nix-darwin --accept-flake-config -- switch --flake .#k99-lite-darwin";

          scripts."10r".exec = ''
            cd $DEVENV_ROOT

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.100\n"' &

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.101\n"' &

            sh -c $'sleep 0.414;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.102\n"' &

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.103\n"' &

            sh -c $'sleep 0.414;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.104\n"' &

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.105\n"' &

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.106\n"' &

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.107\n"' &

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.108\n"' &

            sh -c $'sleep 0.314;zellij -s r10 -s r10 action write-chars "zellij run -- nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@192.168.0.109\n"' &

            zellij --session r10 || zellij attach r10
          '';

          enterShell = ''
            hello
          '';

          # https://devenv.sh/languages/
          languages.nix = {enable = true;};

          # Make diffs fantastic
          difftastic.enable = true;

          # https://devenv.sh/pre-commit-hooks/
          git-hooks.hooks = {
            alejandra.enable = true;
            editorconfig-checker.enable = true;
          };

          # devenv 默认生成 container-shell / container-processes 两个 OCI 输出，
          # 它们依赖 Linux-only 的 shadow，会让 `nix flake check` 在 darwin 上
          # 直接失败。本仓库从不构建容器，关掉。
          containers = nixpkgs.lib.mkForce {};

          # Plugin configuration
        };
        # 让 `nix fmt` 真正可用：treefmt-nix 会填充 formatter.<system>
        # 与 checks.<system>.treefmt。此前本 flake 没有 formatter 输出，
        # treefmt.toml 是死配置，.vscode/settings.json 的 nix.formatterPath 也失效。
        treefmt = {
          projectRootFile = "flake.nix";

          programs.alejandra.enable = true;
          programs.prettier.enable = true;
          programs.shfmt.enable = true;

          settings.global.excludes = [
            # nvfetcher 生成，绝不可手改（.nix 与 .json 两份）
            "pkgs/_sources/**"
            # Deno 机群脚本：Phase 6 会用 clan inventory 重写、Phase 7 删除。
            # 现在让 prettier 翻它们的引号风格只会制造 review 噪音。
            "scripts/makcoo/**"
            # 上游抄来的窗口管理器配置，不按本仓库风格排版
            "*.js"
            "*.lua"
            # 命令式 KDE 主题状态，不是源码
            "mutable/**"
            # 二进制与素材
            "assets/**"
            "*.crx"
            "*.png"
            "*.svg"
            "*.pem"
            # 转储的 shell 历史，不是文档
            "history.md"
            "flake.lock"
          ];
        };

        # 未声明 input 的护栏。名单在 eval 期从 `inputs` 取，所以沙箱内也能跑。
        checks.undeclared-inputs = pkgs.runCommand "undeclared-inputs" {} ''
          printf '%s\n' ${nixpkgs.lib.escapeShellArgs (["self"] ++ builtins.attrNames inputs)} > declared.txt
          bash ${self}/scripts/verify/check-undeclared-inputs.sh declared.txt ${self}
          touch "$out"
        '';

        # ISO 只在 x86_64-linux 上有意义。此前它在所有 system 上求值，
        # 而它引用的 nixpkgs 路径已不存在，导致 `nix flake check`
        # 在任何平台上 1.2 秒内直接失败 —— 早于任何 host 被求值。
        packages = nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          kde-plasma-iso = inputs.nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            modules = [
              # you can include your own nixos configuration here, i.e.
              # ./configuration.nix
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
              ./hosts/nixos/kde-plasma-iso.nix

              ./users/root.nix
              ./users/nixos.nix
              ./users/i.want.to.believe.nix

              ({...}: {
                environment.etc = {
                  # Creates /etc/nanorc
                  v2rayasub = {
                    text = ''
                      https://v1.v2ai.top/link/vTEeHXssGrhkX7g8?sub=3
                    '';

                    # The UNIX file mode bits
                    mode = "0755";
                  };
                };
              })
            ];
            format = "iso";

            # optional arguments:
            # explicit nixpkgs and lib:
            # pkgs = nixpkgs.legacyPackages.x86_64-linux;
            # lib = nixpkgs.legacyPackages.x86_64-linux.lib;
            # additional arguments to pass to modules:
            # hosts/nixos/kde-plasma-iso.nix 只用 lib 与 inputs；
            # suites / profiles / self 从来没有消费者。
            specialArgs = {inputs = inputs;};

            # you can also define your own custom formats
            # customFormats = { "myFormat" = <myFormatModule>; ... };
            # format = "myFormat";
          };
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
              applications.chromium
              packages
            ];
            games = [game.steam game.uudeck.default];
          };
          home-manager = with self.profiles.home-manager; {
            base = [packages nix misc fonts stylix];
            cli = with cli; [direnv git ssh starship yazi mangohud aria2 nvchad.default];
            gui = with gui; [
              firefox.default
              fcitx5
              kitty
              obs-studio
              zathura
              copyq
              looking-glass-client
              mpv
              chromium.default
            ];
            shells = with shells; [fish zsh nu.default];
            darwin = with darwin;
              [
                nix
                packages
                misc
              ]
              ++ [cli.git cli.direnv cli.ssh cli.starship gui.kitty shells.fish shells.zsh shells.nu.default stylix];
            hyprland = with desktop; [
              window-managers.hyprland.default
              mime
            ];

            managed = with managed; [vscode];
          };

          darwin = with self.profiles.darwin; {
            misc = [apps nix services stylix];
          };
        };

        overlays.default = import ./overlays;

        nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          modules = [
            ./hosts/termux/redmi-k70pro/nix-on-droid.nix

            # list of extra modules for Nix-on-Droid system
            # { nix.registry.nixpkgs.flake = nixpkgs; }
            # ./path/to/module.nix

            # or import source out-of-tree modules like:
            # flake.nixOnDroidModules.module
          ];

          # list of extra special args for Nix-on-Droid modules
          extraSpecialArgs = {
            # rootPath = ./.;
            inputs = inputs;
          };

          # set nixpkgs instance, it is recommended to apply `nix-on-droid.overlays.default`
          pkgs = import nixpkgs {
            system = "aarch64-linux";

            overlays = [
              inputs.nix-on-droid.overlays.default
              # add other overlays
            ];
          };

          # set path to home-manager flake
          home-manager-path = inputs.home-manager.outPath;
        };
      };
    });

  inputs = {
    # nixpkgs.url = "github:I-Want-ToBelieve/nixpkgs/auto-update/v2ray";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/pull/450512/head";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # 用 nixos-unstable 而不是 master：master 不是 Hydra 的 jobset，任意 commit 的
    # 二进制缓存命中靠运气，一旦碰上动 stdenv 的提交，十台教室机就要从源码重建世界。
    # nixos-unstable 只比 master 落后几天，但都是 Hydra 实际构建过的 commit。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # 353f738f（2025-10-11 "fix: types"）把 hyprpanel / plasma-manager 从 inputs
    # 里删掉了，却只修了 darwin 配置的引用，导致全部 8 个 nixosConfigurations
    # 无法求值十个月。
    #
    # 两者都不恢复：
    #   - hyprpanel 已被 nixpkgs 打包（pkgs.hyprpanel），上游 flake 的 overlay 现在
    #     只是个废弃桩，求值时会打印 "Overlay has been removed, ...". 8 处引用已删。
    #   - plasma-manager 随 KDE 一起弃用，见下方 KDE 移除说明。
    # 同理 greetd.nix 改用 pkgs.hyprland，省掉一个带 submodule 的重型 git input。

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    haumea.url = "github:nix-community/haumea";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Hyprland is **such** eye candy

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # my nur repository for my nixos dotfiles
    inur = {
      url = "github:I-Want-ToBelieve/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    # Stylix is a NixOS module which applies the same color scheme, font and wallpaper to a wide range of applications and desktop environments. It also exports utilities for you to use the theme in custom parts of your configuration.
    # https://danth.github.io/stylix/installation.html
    # 曾钉在 pull/1973/head（"fix evaluation on darwin"）。该 PR 已于 2025-11-20
    # 合入 master，所以主线严格包含它，继续钉住只会停在 2025-11 并卡住 kmscon
    # 等选项的迁移。
    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    # stylix.url = "github:danth/stylix/ed91a20c84a80a525780dcb5ea3387dddf6cd2de";

    # @see https://github.com/nix-community/nix-index-database#usage-in-home-manager
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    autohide-tdrop = {
      url = "github:I-Want-ToBelieve/autohide-tdrop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-23.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    extra-substituters = [
      "https://nix-gaming.cachix.org"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://mirrors.ustc.edu.cn/nix-channels/store"

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

{
  description = "ZazaOS";

  outputs = inputs @ {
    self,
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({...}: {
      imports = [
        inputs.devenv.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.clan-core.flakeModules.default
        # L3 主机工厂：nixosConfigurations 与 darwinConfigurations 都由它产出
        ./flake/hosts.nix
      ];

      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      debug = true;

      perSystem = {
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
          packages =
            [
              # clan CLI。用 clan-core 自己产出的那份，保证和 flake 里锁定的
              # clan-core 版本一致；`nix run github:clan-lol/clan-core#clan`
              # 每次都要走网络，而且版本可能与 lock 里的不一致。
              inputs.clan-core.packages.${system}.clan-cli
            ]
            ++ (with pkgs; [nvfetcher zellij amber-lang deno]);

          # https://devenv.sh/basics/
          env = {
            GREET = "🛠️ Let's hack 🧑🏻‍💻";
          };

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
          git-hooks.hooks = {
            alejandra.enable = true;
            editorconfig-checker.enable = true;

            # 不开 statix / deadnix 这两个内置 hook —— 它们要求「零发现」，
            # 而现存 48 条 W20 会让每一次 commit 都被拒。改成跑棘轮：
            # 现有债务放过，新增债务拦下。
            lint-ratchet = let
              runner = pkgs.writeShellApplication {
                name = "lint-ratchet";
                runtimeInputs = [pkgs.statix pkgs.deadnix];
                text = ''
                  root=$(git rev-parse --show-toplevel)
                  exec bash "$root/scripts/verify/lint-ratchet.sh" "$root" 18 0
                '';
              };
            in {
              enable = true;
              name = "lint 棘轮 (statix/deadnix 只降不升)";
              entry = "${runner}/bin/lint-ratchet";
              language = "system";
              # 整仓库计数，不是逐文件检查，所以不接受文件名参数。
              pass_filenames = false;
              files = "\\.nix$";
            };
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

          programs = {
            alejandra.enable = true;
            prettier.enable = true;
            shfmt.enable = true;
          };

          settings.global.excludes = [
            # nvfetcher 生成，绝不可手改（.nix 与 .json 两份）
            "pkgs/_sources/**"
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

        # lint 棘轮：statix / deadnix 的发现数只允许下降。
        #
        # 上限不是零，因为 statix 剩下的 48 条全是 W20（重复 key），它只报不修 ——
        # 需要人工把 a.b = …; a.c = …; 合并成 a = { b = …; c = …; };。那是代码形态
        # 偏好而不是缺陷，为它改二十几个文件属于零收益的 churn。
        # deadnix 一侧已清到 0（生成文件之外），所以那边就是硬零。
        #
        # 改这两个数字的唯一正当理由是**调低**。调高等于承认新引入了 lint 债。
        checks.lint-ratchet =
          pkgs.runCommand "lint-ratchet" {
            nativeBuildInputs = [pkgs.statix pkgs.deadnix];
          } ''
            bash ${self}/scripts/verify/lint-ratchet.sh ${self} 18 0
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

              (_: {
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
            specialArgs = {inherit inputs;};

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
            inherit inputs;
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

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # L4'：机群管理。clan-core 自带 disko 与 sops-nix，所以本仓库不再单独声明
    # disko，agenix 也由 clan 的 vars 取代。
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        # clan 自带一份 nix-darwin。目前两边恰好锁在同一个 rev，但它们是独立节点，
        # 下次 nix flake update 就会各自漂 —— 而 k99-lite-darwin 现在由 clan 构建，
        # 用哪一份 nix-darwin 直接决定这台机的结果。
        nix-darwin.follows = "nix-darwin";
      };
    };

    # 353f738f（2025-10-11 "fix: types"）把 hyprpanel / plasma-manager 从 inputs
    # 里删掉了，却只修了 darwin 配置的引用，导致全部 8 个 nixosConfigurations
    # 无法求值十个月。
    #
    # 两者都不恢复：
    #   - hyprpanel 已被 nixpkgs 打包（pkgs.hyprpanel），上游 flake 的 overlay 现在
    #     只是个废弃桩，求值时会打印 "Overlay has been removed, ...". 8 处引用已删。
    #   - plasma-manager 随 KDE 一起弃用，见下方 KDE 移除说明。
    # 同理 greetd.nix 改用 pkgs.hyprland，省掉一个带 submodule 的重型 git input。

    haumea.url = "github:nix-community/haumea";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    # KineticWE —— 带原生平铺的 KWin 分支，上游 flake 里已经把 noctalia shell
    # 一起打包好了（它的 inputs.noctalia 直接指向 noctalia-dev/noctalia）。
    # 这是 zaza-vm 的桌面。选它而不是 Hyprland 的理由只有一条、但是决定性的：
    # 要精确模仿 macOS 就要全局菜单栏，而 kde-appmenu 这个 Wayland 协议
    # 只有 KWin 系实现。
    #
    # 刻意**不**加 inputs.nixpkgs.follows：它自己钉的 nixpkgs 是 2026-06-29，
    # 我们是 2026-08-26。强行统一能避免闭包里出现两套 Qt/KDE，但 KWin 分支对
    # KDE Frameworks 版本很敏感，先用上游自测过的组合把东西跑通，等量过闭包
    # 大小再决定。改这一行之前请先确认它还能构建。
    kineticwe.url = "gitlab:theblackdon/kineticwe";

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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  # 构建**这个 flake 本身**时提供的缓存（需 --accept-flake-config，本仓库到处都带）。
  # 与机器配置里的 nix.settings.substituters 是两回事，后者在
  # profiles/nixos/nix.nix，那里是机器上生效的唯一一处。
  #
  # 曾经有 11 个，其中 6 个已删 —— 每个够不着的 substituter 都要在每次构建时
  # 白等一次连接超时：
  #   nix-gaming / nixpkgs-wayland / helix / hyprland  对应 input 均已在之前的
  #                                                    清理中删除，缓存随之失去意义
  #   fortuneteller2k / nrdxp                          他人的个人缓存，无对应 input
  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    extra-substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org" # devenv input 仍在
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}

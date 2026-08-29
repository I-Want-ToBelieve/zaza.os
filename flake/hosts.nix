# L3：主机工厂。
#
# 取代 flake.nix 里 8 个复制粘贴出来的 nixosConfigurations 区块和 1 个
# darwinConfigurations 区块。
#
# mkHost 返回的是**一个 NixOS module**，不是构建好的系统。这一点是刻意的：同一个函数
# 既能喂给 lib.nixosSystem（现在），也能喂给 clan.machines.<name>（Phase 6），
# 消费者可替换。
#
# 形态选择：普通函数 + 严格命名参数。理由是免费的拼写检查 —— mkHost { stylyx = false; }
# 会立刻报 "called with unexpected argument 'stylyx'"。attrset + recursiveUpdate 或嵌套
# evalModules 都给不了这个，而这是 Nix 里最便宜的正确性保障。
{
  self,
  inputs,
  ...
}: let
  # 显式用 nixpkgs 的 lib，不用 flake-parts 注入的那个 —— 后者来自 flake-parts 自己的
  # nixpkgs-lib 输入，可能与本仓库的 nixpkgs 漂移。
  inherit (inputs.nixpkgs) lib;

  ## ------------------------------------------------------------------ ##
  ## 1. 全部主机逐字节相同的部分。经逐行比对确认，在出现第二个不同的      ##
  ##    主机之前不要参数化。                                             ##
  ## ------------------------------------------------------------------ ##

  permittedInsecurePackages = [
    "electron-13.6.9"
    "electron-19.0.7"
    "openssl-1.1.1v"
    "openssl-1.1.1w"
    "python3.11-django-3.1.14"
  ];

  # 原来的 share.overlays
  commonOverlays = [
    (_final: prev: {inur = inputs.inur.packages."${prev.system}";})
    (_final: prev: {nvchad = inputs.nvchad4nix.packages."${prev.system}".nvchad;})
  ];

  nixosOverlays =
    commonOverlays
    ++ [
      inputs.nur.overlays.default
      inputs.agenix.overlays.default
      inputs.nvfetcher.overlays.default
      inputs.rust-overlay.overlays.default
      (import ../pkgs)
      self.overlays.default
    ];

  # darwin 少了 agenix，多一个 karabiner-elements 的 stable 固定。
  darwinOverlays =
    commonOverlays
    ++ [
      # https://github.com/LnL7/nix-darwin/issues/1041
      (_final: prev: {
        inherit (inputs.nixpkgs-stable.legacyPackages.${prev.system}) karabiner-elements;
      })
      inputs.nur.overlays.default
      inputs.nvfetcher.overlays.default
      inputs.rust-overlay.overlays.default
      (import ../pkgs)
      self.overlays.default
    ];

  mkNixpkgsModule = {
    overlays,
    hostPlatform ? null,
  }: {
    # 注意：合并必须发生在 nixpkgs **内部**。写成
    #   { nixpkgs.overlays = …; } // { nixpkgs.hostPlatform = …; }
    # 是浅合并，会把整个 nixpkgs 属性替换掉，overlays 和 config 全部丢失
    # （症状：pkgs.nur 不存在）。
    nixpkgs =
      {
        inherit overlays;
        config = {
          allowUnfree = true;
          inherit permittedInsecurePackages;
        };
      }
      // lib.optionalAttrs (hostPlatform != null) {inherit hostPlatform;};
  };

  ## ------------------------------------------------------------------ ##
  ## 2. home-manager。mkHost 与 mkDarwin 唯一共用的实质代码。            ##
  ## ------------------------------------------------------------------ ##

  # sharedModules 前置、extras 后置，复现原来的顺序：
  #   attrValues homeManagerModules ++ suites ++ [nix-index …] ++ inline
  # standardExtras = false 同时去掉两者，这正是两个 -minimal 主机需要的形态
  # （它们的用户块里只有 home.stateVersion）。
  mkHmUser = {
    sharedModules,
    extras,
  }: {
    suites ? [],
    modules ? [],
    standardExtras ? true,
    stateVersion,
  }: {
    imports =
      lib.optionals standardExtras sharedModules
      ++ lib.flatten suites
      ++ lib.optionals standardExtras extras
      ++ modules;
    home.stateVersion = stateVersion;
  };

  mkHmBlock = {
    sharedModules,
    extras,
    users,
  }: {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "homebak";
    extraSpecialArgs = {inputs = inputs;};
    users = lib.mapAttrs (_name: mkHmUser {inherit sharedModules extras;}) users;
  };

  # 两处上游改名，都在这里集中处理（此前分散在 8 个 host block 里）：
  #   nix-index-database.hmModules -> homeModules（hmModules 现为废弃别名）
  #   nvchad4nix.homeManagerModule -> homeManagerModules.default
  nixosHmExtras = [
    inputs.nix-index-database.homeModules.nix-index
    inputs.nvchad4nix.homeManagerModules.default
    {programs.nix-index-database.comma.enable = true;}
  ];

  darwinHmExtras = [
    inputs.nix-index-database.homeModules.nix-index
    {programs.nix-index-database.comma.enable = true;}
  ];

  ## ------------------------------------------------------------------ ##
  ## 3. mkHost                                                          ##
  ## ------------------------------------------------------------------ ##

  mkHost = {
    # ---- 身份 ----
    name, # 机器名，同时用作 networking.hostName
    hostFile, # ./hosts/** 下的主机文件
    system ? "x86_64-linux", # 目前 8 台全是它
    # ---- 内容 ----
    suites ? [], # nixos suite 列表，会被 flatten
    users ? {}, # 用户名 -> home-manager 用户记录
    modules ? [], # 逐机逃生口（nixos-wsl 走这里）
    # ---- 真正的单机例外 ----
    stylix ? true, # 两个 -minimal 不要
    # 三态：null 完全不导入 disko / {} 导入但不传 disks / {disks=[…];} 两者都做。
    # 必须三态：hosts/nixos/lenovo-a6-6310/disk-config.nix 根本不接 disks 参数
    # （硬编码 lib.mkDefault "/dev/sda"），而 dell-makcoo 的接 disks ? ["/dev/nvme1n1"]。
    # 若无条件传 disks = null，会顶掉 dell-makcoo 自己的默认值并在 elemAt 处崩。
    disko ? null,
    # flake 内联的 stateVersion。**不要**把它「清理」成 "24.05"：
    # 7 台主机各自的 hosts/*.nix 用 lib.mkForce "24.05" 覆盖了它，唯独
    # hosts/wsl/k99-lite-wsl.nix:72 写的是平凡的 "23.11"，仅因与此处相等才没冲突。
    # 改成 "24.05" 会让 k99-lite-wsl 变成硬求值错误。
    systemStateVersion ? "23.11",
  }: {
    # 此前**没有任何** NixOS 主机设置过 hostName，8 台全部落到默认值 `nixos` ——
    # 每个 drv 都叫 nixos-system-nixos-* 就是证据。
    #
    # 用 mkDefault，这样各主机文件仍可覆盖，Phase 6 里 clan 自己的
    # `networking.hostName = lib.mkDefault name` 也不会冲突。
    #
    # 注意这不能算「修好了机群身份」：dell-makcoo 这一份配置被部署到十台机器上，
    # 于是那十台会同时叫 dell-makcoo。相比现在十台都叫 nixos 不算退步，但真正的
    # 逐机身份要等 clan 给出十个独立的 machine。
    networking.hostName = lib.mkDefault name;

    imports =
      lib.attrValues self.nixosModules
      ++ lib.optional (disko != null && disko ? disks) {
        _module.args = {inherit (disko) disks;};
      }
      ++ [
        (mkNixpkgsModule {
          overlays = nixosOverlays;
          hostPlatform = system;
        })
      ]
      ++ lib.optional (suites != []) {imports = lib.flatten suites;}
      ++ modules
      ++ [inputs.home-manager.nixosModules.home-manager]
      ++ lib.optional stylix inputs.stylix.nixosModules.stylix
      ++ lib.optional (disko != null) inputs.disko.nixosModules.disko
      ++ [
        {
          system.stateVersion = systemStateVersion;
          system.autoUpgrade.enable = false;
        }

        inputs.agenix.nixosModules.default
        hostFile

        ../users/root.nix
        ../users/i.want.to.believe.nix

        {
          home-manager = mkHmBlock {
            sharedModules = lib.attrValues self.homeManagerModules; # 目前是 []
            extras = nixosHmExtras;
            inherit users;
          };
        }
      ];
  };

  # 过渡适配器。它的存在只是为了让工厂在 clan 进场之前就能被证明等价；
  # Phase 6 换成 clan.machines 后即可删除。
  mkNixos = args:
    lib.nixosSystem {
      inherit (args) system;
      # 只剩 inputs。它必须留在 specialArgs：12 个主机文件在 imports 内部使用它，
      # 而实测用 _module.args 替代会无限递归（nixpkgs 自带提示 "argument is not
      # externally provided, so querying `_module.args` instead, requiring `config`"）。
      #
      # self 与 suites 已移除，两者都没有真实消费者：
      #   - suites 只被 hosts/nixos/NixOS.nix 读取，而该文件不被任何配置引用（已删）
      #   - self 的唯一 body 用法是 ${self}/lib/compat，指向一个不存在的目录
      specialArgs = {inputs = inputs;};
      modules = [(mkHost args)];
    };

  ## ------------------------------------------------------------------ ##
  ## 4. mkDarwin —— 独立函数，不做 mkSystem { platform = … }。          ##
  ##    两者有 13 处结构性差异对 5 处相似，统一只会把布尔汤搬进工厂内部。 ##
  ## ------------------------------------------------------------------ ##

  # 返回的是**模块列表**，不是单个 module —— 这一点与 mkHost 不同，且是必须的。
  # 把原本扁平的列表包进一层 { imports = [ … ]; } 会改变这些模块相对于 nix-darwin
  # 自身 baseModules 的次序，进而改变 environment.systemPackages 的拼接顺序：
  # 实测 system-path 里 darwin-uninstaller/version/rebuild/option 与
  # profiles/darwin/apps.nix 的 neovim/git/skhd 会前后互换，drvPath 随之改变。
  # （NixOS 那边包一层不受影响，8/8 逐字节一致；darwin 敏感。）
  mkDarwinModules = {
    hostFile,
    suites ? [],
    users ? {},
    stateVersion ? 5, # darwin 是整数，NixOS 是字符串
    modules ? [],
  }:
  # 顺序照抄原区块：nixpkgs -> {stateVersion} -> suites -> hostFile -> …
    [
      (mkNixpkgsModule {overlays = darwinOverlays;}) # darwin 不设 nixpkgs.hostPlatform
      {system.stateVersion = stateVersion;}
    ]
    ++ lib.optional (suites != []) {imports = lib.flatten suites;}
    ++ [
      hostFile
      ../users/darwin/i.want.to.believe.nix
      # 刻意没有 users/root.nix、没有 agenix、没有 system.autoUpgrade
      inputs.home-manager.darwinModules.home-manager
      inputs.stylix.darwinModules.stylix
      {
        home-manager = mkHmBlock {
          sharedModules = []; # darwin 刻意不含 attrValues self.homeManagerModules
          extras = darwinHmExtras;
          inherit users;
        };
      }
    ]
    ++ modules;

  mkDarwin = {system, ...} @ args:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      # 刻意不传 specialArgs：hosts/darwin/k99-lite-darwin.nix 和四个
      # profiles/darwin/*.nix 只用 pkgs / lib，且都带 ...
      modules = mkDarwinModules (builtins.removeAttrs args ["system"]);
    };

  nixosSuites = self.suites.nixos;
  hmSuites = self.suites.home-manager;
  darwinSuites = self.suites.darwin;

  # 为 root 用户配置指向机群的 ssh key。xiaoxin 两台共用，逐字保留。
  fleetRootSsh = _: {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "192.168.0.*" = {
          identityFile = "~/.ssh/thinkpad_t420s_root_id_rsa";
        };
      };
    };
  };

  ## ------------------------------------------------------------------ ##
  ## 5. 机器清单                                                        ##
  ## ------------------------------------------------------------------ ##

  iwtb = suites: {
    "i.want.to.believe" = {
      inherit suites;
      stateVersion = "23.11";
    };
  };

  machines = {
    k99-lite = {
      hostFile = ../hosts/nixos/k99-lite.nix;
      suites = with nixosSuites; [base misc games];
      users = iwtb (with hmSuites; [base cli gui shells]);
    };

    k99-lite-wsl = {
      hostFile = ../hosts/wsl/k99-lite-wsl.nix;
      suites = with nixosSuites; [base misc];
      # 唯一需要额外顶层 NixOS module 的主机。它是列表里的一项，不是 wsl = true 开关。
      modules = [inputs.nixos-wsl.nixosModules.wsl];
      users = iwtb (with hmSuites; [base cli gui shells]);
    };

    xiaoxin-pro16-2021 = {
      hostFile = ../hosts/nixos/xiaoxin-pro16-2021.nix;
      suites = with nixosSuites; [base misc games];
      users =
        iwtb (with hmSuites; [base cli gui shells])
        // {
          root = {
            # 注意：这里是 hyprland，而 xiaoxin-pro14-2021 的 root 用的是普通组。
            # 两个区块其余部分字符级相同，疑似复制粘贴事故。此处逐字保留，
            # 若确认是意外应单独修。
            suites = with hmSuites; [base cli gui shells hyprland];
            modules = [fleetRootSsh];
            stateVersion = "23.11";
          };
        };
    };

    xiaoxin-pro14-2021 = {
      hostFile = ../hosts/nixos/xiaoxin-pro14-2021.nix;
      suites = with nixosSuites; [base misc games];
      users =
        iwtb (with hmSuites; [base cli gui shells])
        // {
          root = {
            suites = with hmSuites; [base cli gui shells];
            modules = [fleetRootSsh];
            stateVersion = "23.11";
          };
        };
    };

    dell-makcoo = {
      hostFile = ../hosts/nixos/dell-makcoo/default.nix;
      suites = with nixosSuites; [base misc];
      disko = {disks = ["/dev/nvme0n1"];};
      users = iwtb (with hmSuites; [base cli gui shells managed]);
    };

    dell-makcoo-minimal = {
      hostFile = ../hosts/nixos/dell-makcoo/minimal.nix;
      # nixos-anywhere 用的裸装变体：不导入任何 nixos suite（故省略 suites），
      # 也不要主题。
      stylix = false;
      disko = {disks = ["/dev/sda"];};
      users."i.want.to.believe" = {
        # 连标准 HM 附加项也不要：那会把 nvchad / nix-index / comma 拉进一台
        # 存在意义就是小闭包的机器。
        standardExtras = false;
        stateVersion = "23.11";
      };
    };

    lenovo-a6-6310 = {
      hostFile = ../hosts/nixos/lenovo-a6-6310/default.nix;
      suites = with nixosSuites; [base misc];
      # 导入 disko，但**不传** disks —— 它的 disk-config.nix 不接这个参数。
      disko = {};
      users = iwtb (with hmSuites; [base cli gui shells managed]);
    };

    lenovo-a6-6310-minimal = {
      hostFile = ../hosts/nixos/lenovo-a6-6310/minimal.nix;
      stylix = false;
      disko = {};
      users."i.want.to.believe" = {
        standardExtras = false;
        stateVersion = "23.11";
      };
    };
  };
in {
  flake.nixosConfigurations = lib.mapAttrs (name: def:
    mkNixos ({
        system = "x86_64-linux";
        inherit name;
      }
      // def))
  machines;

  flake.darwinConfigurations."k99-lite-darwin" = mkDarwin {
    system = "aarch64-darwin";
    hostFile = ../hosts/darwin/k99-lite-darwin.nix;
    suites = with darwinSuites; [misc];
    users."i.want.to.believe" = {
      suites = with hmSuites; [darwin];
      stateVersion = "24.05"; # 对比每台 Linux 主机的 "23.11"
    };
  };
}

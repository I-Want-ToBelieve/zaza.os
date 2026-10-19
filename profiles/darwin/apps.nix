{pkgs, ...}: {
  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  # TODO Fell free to modify this file to fit your needs.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    neovim
    git
    skhd
  ];
  # nvim，不是 neovim：包名叫 neovim，可执行文件叫 nvim。
  # 此前这里是 "neovim"，而本机并不存在该命令，任何读 $EDITOR 的工具都会失败。
  environment.variables.EDITOR = "nvim";
  environment.shells = [pkgs.fish];

  # Homebrew Mirror in China
  # Feel free to remove this if you are not in China.
  environment.variables = {
    HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
  };

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://githubfast.com/mas-cli/mas
    masApps = {
      # TODO Feel free to add your favorite apps here.

      # Xcode = 497799835;
      # Wechat = 836500024;
      # NeteaseCloudMusic = 944848654;
      # QQ = 451108668;
      # WeCom = 1189898970;  # Wechat for Work
      # TecentMetting = 1484048379;
      # QQMusic = 595615424;
    };

    taps = [
      # "homebrew/cask"
      #  "homebrew/cask-fonts"
      "homebrew/services"
      # "homebrew/cask-versions"
      "v2raya/v2raya"
      "FelixKratz/formulae"
      "I-Want-ToBelieve/homebrew-formulae"
      "LizardByte/homebrew"
      "jackmordaunt/homebrew-tap"
      "oven-sh/bun"
    ];

    # `brew install`
    # TODO Feel free to add your favorite apps here.
    brews = [
      "wget" # download tool
      "curl" # no not install curl via nixpkgs, it's not working well on macOS!
      "v2raya/v2raya/v2raya"
      "borders"
      "proxychains-ng"
      "clang-format"
      "mas"
      "rust"
      "node"
      "yakite"
      "yakite-toast"
      "qemu"
      "lima"
      "yazi"
      "fnm"
      "pnpm"
      "icnsify"
      # "sunshine"

      # 以下是本机实际装着、此前未声明的顶层 formula。
      # cleanup = "zap" 会卸载一切未声明的东西，所以漏掉它们就等于在下一次
      # 切换时把它们删掉。判据是 `brew leaves`（不被其它已装包依赖的包）——
      # 传递依赖不用列，brew bundle cleanup 会保留被声明包依赖的那些。
      # 例：llvm@19 是 rust 的依赖，因而刻意不在这里。
      "act"
      "rclone"
      "rsync"
      "uv"
      # bun 既不是任何已装包的依赖，也不在 brew leaves 里（它是以依赖身份
      # 装进来的，而那个依赖者已经没了）。不显式声明就会被 zap 清掉。
      "oven-sh/bun/bun"
    ];

    # `brew install --cask`
    # TODO Feel free to add your favorite apps here.
    casks = [
      # "openinterminal-lite" # open current folder in terminal
      "firefox"
      "raycast"
      "alt-tab"
      "copyq"
      "monitorcontrol"
      "easy-move+resize" # 规范 token；easy-move-plus-resize 是它的别名
      "phoenix"
      "hackintool"
      # "docker"
      "kap"
      "keycastr"
      "switchhosts"
      "termius"
      "zerotier-one"
      "snipaste"
      "google-chrome"
      "maccy"
      # "spacedrive"
      # "wave"
      # "iglance" # beautiful system monitor
      # "eudic" # 欧路词典

      # 同上：本机实际装着但此前未声明，不补就会被 zap 卸掉。
      # claude-code 和 orbstack 尤其要紧 —— 卸掉它们是实打实的损失，
      # 而且 homebrew 这部分**不在** nix-darwin 的 generation 回滚范围内。
      "claude-code"
      "orbstack"
      "android-platform-tools"
      "mitmproxy"
      "openmtp"
      "font-maple-mono-nf-cn"
    ];
  };
}

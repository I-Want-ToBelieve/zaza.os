# 常用终端与开发工具集；云平台、Kubernetes、本地 AI 和其他 GUI 按需添加。
{pkgs, ...}: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        ${pkgs.zoxide}/bin/zoxide init fish | source
        ${pkgs.fzf}/bin/fzf --fish | source
        ${pkgs.atuin}/bin/atuin init fish --disable-up-arrow | source
      '';
      shellAliases = {
        ll = "eza -lah --group-directories-first";
        lt = "eza --tree --level=2";
        lg = "lazygit";
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      config = {
        init.defaultBranch = "main";
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta.navigate = true;
        merge.conflictStyle = "zdiff3";
      };
    };
  };

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];
  environment = {
    variables.EDITOR = "hx";
    systemPackages = with pkgs; [
      # 文件、搜索、结构化文本和交互式历史。
      ripgrep
      fd
      fzf
      bat
      eza
      zoxide
      atuin
      jq
      yq-go
      miller
      zip
      unzip
      # 开发与项目自动化；语言工具链由各项目 devShell 管理。
      delta
      gh
      just
      nix-output-monitor
      uv
      ruff
      shellcheck
      shfmt
      watchexec
      hyperfine
      # 传输、备份、加密与媒体批处理；不自动创建后台服务。
      curl
      wget
      aria2
      openssh
      rsync
      rclone
      restic
      age
      sops
      ffmpeg
      yt-dlp
      # TUI 与会话管理。
      helix
      yazi
      lazygit
      btop
      nvtopPackages.full
      ncdu
      lnav
      tmux
      zellij
      # 系统诊断和 Wayland 管道工具。
      fastfetch
      pciutils
      usbutils
      smartmontools
      iperf3
      wl-clipboard
    ];
  };
}

# 把图形会话通过 VNC / noVNC 导出。
#
# 存在的理由：zaza-vm 没有物理显示器，而 QEMU 的 virtio-gpu-pci 只提供
# dumb buffer、没有 virgl，所以 Hyprland 的 DRM 后端很可能起不来 ——
# Hyprland 已经砍掉 pixman 软件渲染器，是纯 GLES 的。
#
# 正解是绕开 DRM：用 wlroots 的 **headless 后端**建一个纯内存的虚拟输出，
# GLES 交给 Mesa 的 llvmpipe 做软件渲染，再由 wayvnc 把这块 buffer 推出去。
# 这条链路不碰任何显卡，所以宿主有没有 3D 转发都不影响它能不能跑。
#
# noVNC 那一层是为了**能被浏览器打开** —— 这样开发桌面时可以直接在浏览器里
# 看到并操作这个会话，不需要本地装 VNC 客户端。
{
  lib,
  pkgs,
  ...
}: let
  user = "i.want.to.believe";

  # 分辨率取小是刻意的：llvmpipe 是纯 CPU 渲染，像素数直接决定合成开销。
  # 1280x800 在 6 GB / 软件渲染下仍然跟手，且在浏览器窗口里读得清。
  width = 1280;
  height = 800;

  vncPort = 5900; # wayvnc
  webPort = 6080; # noVNC 的 http

  # Hyprland 在 headless 后端下不会自动建输出，要显式 create。
  hyprlandConf = pkgs.writeText "hyprland-headless.conf" ''
    monitor = HEADLESS-1, ${toString width}x${toString height}@60, 0x0, 1

    # 没有物理输入设备；输入全部来自 wayvnc 的 VNC 通道。
    exec-once = ${pkgs.wayvnc}/bin/wayvnc --output=HEADLESS-1 0.0.0.0 ${toString vncPort}

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
    }

    # 一个能开出来的终端，作为「会话确实活着」的最小证据。
    bind = SUPER, Return, exec, ${pkgs.foot}/bin/foot
  '';
in {
  programs.hyprland.enable = true;

  # wlroots 默认拒绝在软件渲染器上跑，必须显式放行。
  # 注意变量名是 WLR_BACKENDS（复数，选后端）和 WLR_RENDERER（选渲染器）——
  # profiles/nixos/display-managers/greetd.nix 里的 `WLR_BACKEND = "vulkan"`
  # 是单数且赋的是渲染器的值，那一处是无效设置（该 profile 目前无消费者）。
  environment.sessionVariables = {
    WLR_BACKENDS = "headless";
    WLR_RENDERER = "gles2";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    WLR_LIBINPUT_NO_DEVICES = "1";
    LIBGL_ALWAYS_SOFTWARE = "1";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # greetd 负责 PAM / logind 会话 —— 这是 XDG_RUNTIME_DIR、seat 和
  # dbus 用户总线能正确建立的原因。自己写 systemd system service 跑
  # 合成器要手工复刻这一整套，不值得。
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland --config ${hyprlandConf}";
        inherit user;
      };
      default_session = initial_session;
    };
  };

  # noVNC：websockify 同时充当静态文件服务器（-w 指向 novnc 的 web 根）
  # 和 WebSocket→TCP 代理。一个进程搞定，不需要额外的 nginx。
  systemd.services.novnc = {
    description = "noVNC web 前端（浏览器打开 http://localhost:${toString webPort}/vnc.html）";
    wantedBy = ["multi-user.target"];
    after = ["greetd.service"];
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.python3Packages.websockify}/bin/websockify"
        "--web=${pkgs.novnc}/share/webapps/novnc"
        "0.0.0.0:${toString webPort}"
        "127.0.0.1:${toString vncPort}"
      ];
      Restart = "always";
      RestartSec = 3;
      DynamicUser = true;
    };
  };

  # 开发这台机器时会反复用到的东西。刻意保持很小 —— 桌面本身该由
  # suites 决定，这里只放「看得见、点得动」所必需的。
  environment.systemPackages = with pkgs; [
    wayvnc
    novnc
    foot # headless 会话里第一个能开出来的窗口
    wl-clipboard
    wlr-randr # 改虚拟输出分辨率，不用重启合成器
    grim # 在 guest 内部截图，与 VNC 那条路互为佐证
  ];
}

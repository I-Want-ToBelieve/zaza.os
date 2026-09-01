# zaza-vm 的图形会话：KineticWE（KWin 分支 + noctalia shell）。
#
# ── 为什么是 KWin 系而不是 Hyprland ────────────────────────────────────
# 目标是精确模仿 macOS，而 macOS 最标志性的是全局菜单栏。承载它的
# `kde-appmenu` Wayland 协议**只有 KWin 系实现** —— Hyprland 结构上给不了。
# 这是整个桌面选型的唯一决定性理由。
#
# ── 画面怎么出来 ──────────────────────────────────────────────────────
# 走 **QEMU 侧的 VNC**，guest 里一个 VNC 软件都不装。此前这里用的是 wayvnc，
# 那是错的：nixpkgs 对它的描述就是 "VNC server for **wlroots based** Wayland
# compositors"，而 KWin 不是 wlroots，这条链路对它根本不成立。
#
# QEMU 侧还有两个附带好处：
#   - 键鼠由 QEMU 经 virtio-input 注入，libinput 直接看到，不用额外配置；
#   - **合成器起不来时照样看得见**引导过程和 tty —— 调一个可能起不来的桌面
#     时，这条性质比清晰度重要得多。
#
# 之所以敢让 KWin 直接画到 QEMU 那块没有 3D 的 virtio-gpu 上：KWin 保留了
# 软件合成后端（源码里的 src/backends/drm/drm_qpainter_backend.cpp），
# 正是 Hyprland 砍掉的那个。KWIN_COMPOSE=Q 强制选它。
{
  inputs,
  pkgs,
  ...
}: let
  user = "i.want.to.believe";
in {
  imports = [inputs.kineticwe.nixosModules.default];

  # 一个开关装齐 kwin-we + noctalia + 装饰件，并把 KineticWE 注册成一个
  # 真正的 Wayland session（走 services.displayManager.sessionPackages，
  # 不是会生成 X11 包装器的老 displayManager.session）。
  programs.kineticwe.enable = true;

  # QEMU 的 virtio-gpu-pci 只有 dumb buffer，没有 virgl —— 强制走 QPainter
  # 软件合成，否则 KWin 会去试 OpenGL 然后失败回退（能起来，但日志很吵，
  # 且回退路径不如显式选择可预测）。
  environment.sessionVariables = {
    KWIN_COMPOSE = "Q";
    LIBGL_ALWAYS_SOFTWARE = "1";
    NIXOS_OZONE_WL = "1";
  };

  # greetd 负责 PAM / logind 会话 —— XDG_RUNTIME_DIR、seat、dbus 用户总线
  # 都由它建立。自己写 systemd service 跑合成器要手工复刻这一整套。
  #
  # 自动登录：这是一台本地开发 VM，画面经 QEMU 只暴露给宿主的 127.0.0.1，
  # 不在任何真实网络上。省掉每次改配置后手工输密码。
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.kineticwe}/bin/start-kineticwe";
        inherit user;
      };
      default_session = initial_session;
    };
  };

  # 开发这个桌面本身会用到的。刻意很小 —— 桌面的内容由 KineticWE 自带的
  # noctalia 决定，这里只放「看得见、点得动、查得了」所必需的。
  environment.systemPackages = with pkgs; [
    foot # 最小的终端，会话起来后第一个能开的窗口
    wl-clipboard
    wlr-randr # 改输出分辨率，不必重启合成器
    grim # guest 内部截图，与 QEMU 那条 VNC 路互为佐证
    libnotify
  ];
}

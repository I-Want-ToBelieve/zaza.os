# MacTahoe 桌面

Tahoe 候选窗与雾凇拼音的配置、按键和验证边界见 [INPUT-METHOD.md](INPUT-METHOD.md)。

`lvlv.os` 与 `lvlv-vm` 的 `i.want.to.believe` 共用
[`profiles/home-manager/desktop/mactahoe.nix`](../../../profiles/home-manager/desktop/mactahoe.nix)。
Home Manager 由 NixOS 的 `mkHost` 集成，`standardExtras = false`；
没有引入原来的 CLI / GUI 大套件，也不为 root 设置桌面。

## 来源与管理边界

| 内容 | 上游 / 配置 |
| --- | --- |
| Plasma、配色、Aurorae 装饰、Kvantum、壁纸 | [MacTahoe-kde](https://github.com/vinceliuice/MacTahoe-kde)，`mactahoe-kde` flake input |
| GTK 2/3 应用主题、可选 GTK4/libadwaita CSS | [MacTahoe-gtk-theme](https://github.com/vinceliuice/MacTahoe-gtk-theme)，`mactahoe-gtk` input |
| 图标、Xcursor / SVG 光标 | [MacTahoe-icon-theme](https://github.com/vinceliuice/MacTahoe-icon-theme)，`mactahoe-icons` input |
| KDE 配置、面板与快捷键 | [plasma-manager](https://github.com/nix-community/plasma-manager)，跟随仓库的 nixpkgs / Home Manager |
| 字体 | 开源 Inter、JetBrains Mono，中文回退到已有 Noto CJK |

四个上游版本及内容哈希由 `flake.lock` 固定；主题包入口为
[`pkgs/mactahoe/default.nix`](../../../pkgs/mactahoe/default.nix)，
KDE、GTK 和图标分别定义在同目录的 `kde.nix`、`gtk.nix`、`icons.nix`。
KDE 资源直接复制到 Nix store：上游安装脚本按 UID 分支且部分路径忽略 `--dest`，
因此不会用它修改用户目录。图标与 GTK 安装脚本仅在 Nix 构建沙箱内向 `$out` 写入。
GTK 构建依赖由 Nix 提供，移除上游 sudo 检查和额外的 GNOME 主题切换器安装步骤；
不会安装 GNOME 桌面，也不会在登录时运行上游安装脚本。
不需要在线商店下载、手动复制主题或开机联网安装。

## 默认外观

- 浅色 MacTahoe、蓝色强调色、上游浅色壁纸、24px 光标。
- Aurorae 窗口装饰，左侧关闭 / 最小化 / 最大化按钮；Qt 6 使用 Kvantum。
- 顶部 32px 菜单栏：应用菜单、全局菜单、系统托盘、日期和时间。
- 底部 64px 居中浮动 Dock，随内容调整长度，窗口接近时隐藏。
  固定 Dolphin、Firefox、kitty、VS Code、OBS、Vicinae。
- `Meta+Space` 打开 Vicinae；文件使用单击选中、双击打开。
- GTK 2/3 使用 `MacTahoe-Light-solid`，共享字体、图标、光标及浅色偏好。
  不透明版本不依赖第三方强制模糊插件；GTK4/libadwaita CSS 覆盖默认关闭。
- kitty 使用 Home Manager 管理的浅色配置、JetBrains Mono Nerd Font 和蓝色光标。

plasma-manager 逐项选择主题组件，不调用全局主题的布局脚本，避免后者覆盖声明的面板。
`overrideConfig = false` 保留未声明的用户设置；声明的面板列表归 plasma-manager 管理，
更改布局请编辑该 Nix 模块。面板和壁纸脚本在登录时应用，配置变更后重新登录验证。
验证 VM 会等待 Plasma 桌面就绪再创建面板，并关闭自动息屏和挂起，
避免 TCG 首次启动超时，并保持 VM 预览可见；实机不应用这些设置。
SDDM 仍由 NixOS 管理，Home Manager 不负责登录管理器。

## 模块开关

可复用模块位于 `modules/home-manager/mactahoe-kde.nix` 与 `mactahoe-gtk.nix`，
普通用户经 `mkHost` 的 `sharedModules` 注册；精简的 `lvlvUsers` 显式注册它们，
两个模块都默认关闭。`lvlv.os` / `lvlv-vm` 的现有
`mactahoe.nix` profile 默认开启两个模块，并保留当前面板、Dock、字体和 kitty 设置。
其他主机不会因为注册模块而启用主题。

在目标用户的 Home Manager 配置中设置：

```nix
appearance.mactahoe = {
  kde = {
    enable = true;
    color = "light"; # light / dark
  };
  gtk = {
    enable = true;
    color = "light"; # light / dark
    opacity = "solid"; # solid / normal
    libadwaita.enable = false;
  };
};
```

两个开关独立：`gtk.enable = false` 仅关闭此模块管理的 GTK 主题，
`kde.enable = false` 关闭此 profile 管理的 Plasma / Aurorae / Kvantum 外观和布局。
单独使用可复用模块时不附带 lvlv 的面板、字体、应用快捷键或图标选择。
Kvantum 的 Qt 6 插件仍由主机共用的 NixOS 配置提供，确保系统 Qt 应用能发现它。

`gtk.libadwaita.enable = true` 使用 Home Manager 的 `gtk.gtk4.theme`，
在 `gtk-4.0/gtk.css` 导入 Nix store 中的主题 CSS，适用于愿意使用这一适配方式的用户。
这会固定该 CSS 的配色，部分 GTK4/libadwaita 应用的控件布局或配色仍可能不兼容。
Flatpak 沙箱、自绘界面和 Firefox 专用主题不属于这两个模块的适用范围。

模块回归检查（关闭、GTK 单独、KDE 单独、同时浅色、同时深色、GTK4 CSS）：

```sh
nix eval --impure --json --file scripts/verify/mactahoe.nix
```

2026-10-01 模块化验证：六种模块组合、`lvlv` / `lvlv.os` / `lvlv-vm` 求值、
四种 GTK 主题资源检查，以及完整 `lvlv-vm` 系统构建均通过。
生成的 GTK 2/3 配置选择 `MacTahoe-Light-solid`，Kvantum 保持 `MacTahoe`，
默认未生成 GTK4 覆盖 CSS。锁文件只新增 GTK 输入，没有更新已有依赖。
本次验证没有切换运行中的系统；以下桌面截图记录属于此前 KDE 外观验证。
全仓库 `nix flake check --impure --no-build` 未通过：既有 `devenv-test` 的源码依赖
下载 / 缓存出现错误，原配置的相同目标也遇到该依赖的下载超时。
这项全仓库检查不计为通过，不影响已完成的主题模块、资源包与 VM 系统构建结果。

## 验证与限制

本轮构建和 VM 验证结果见 [VALIDATION.md](VALIDATION.md)。
构建与自动布局已通过。此前 QEMU / QPainter 的窗口交互发生过 KWin 绘制崩溃；
当前 VM 默认采用 WHPX + VirGL 原生 OpenGL，KWin 已识别 RX 6750 XT，
MacTahoe、Dolphin 与 Flameshot 截图通过运行检查。短期检查不代表长期稳定性验收。
在首次激活前将 VM 中的 KDE 配置备份，并固定此前运行系统的 GC root。

仅 `software-rendering` 恢复入口设置 `KWIN_COMPOSE=Q`，其表现不能证明 OpenGL
模糊、窗口动画或硬件性能。配置启用 KWin 内置模糊，没有添加第三方 Better Blur
插件。完整透明 / 模糊效果与实体 GPU 性能仍需在实机验证。
全局菜单仅适用于导出 AppMenu 的应用；Firefox、Electron、GTK 应用不保证支持。

更新时仅更新主题相关输入并重新验证，例如：

```sh
nix flake update plasma-manager mactahoe-kde mactahoe-gtk mactahoe-icons
nix build --accept-flake-config '.#nixosConfigurations.lvlv-vm.config.system.build.toplevel'
```

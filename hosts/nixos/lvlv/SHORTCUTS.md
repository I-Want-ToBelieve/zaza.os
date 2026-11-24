# lvlv 桌面快捷键

普通用户的公共入口由 `profiles/home-manager/desktop/lvlv-shortcuts.nix` 声明，
与主题开关独立。平铺按键见 [TILING.md](TILING.md)，输入法见 [INPUT-METHOD.md](INPUT-METHOD.md)。

| 按键 | 操作 |
| --- | --- |
| Meta+Space | Vicinae 启动器 |
| Meta+Return | kitty 终端 |
| Ctrl+T | 显示 / 隐藏 kitty 快速访问终端 |
| Meta+E | Dolphin 文件管理 |
| Print / Meta+Shift+S | Flameshot 截图与标注 |
| Meta+V | CopyQ 剪贴板历史 |
| Alt+Space / Alt+F2 | KDE KRunner |
| Meta+L | 锁屏 |
| Meta+D | 显示桌面 |
| Meta+W | 桌面总览 |
| Meta+Ctrl+Left / Right | 上一个 / 下一个虚拟桌面 |
| Ctrl+Space | Fcitx5 中英文切换 |
| Meta+Alt+H / J / K / L | 平铺窗口焦点 |
| Meta+Alt+Shift+H / J / K / L | 移动平铺窗口 |
| Meta+Alt+F | 当前窗口平铺 / 浮动 |

Meta 对应 PC 键盘的 Windows 键。Meta+V 从 Klipper 转交给 CopyQ；
KDE 自带剪贴板仍可从系统托盘打开。Spectacle 的历史截图绑定清空，
防止它在未安装时占用 Print。Plasma 剪贴板组件的 Meta+V 也显式清空。
KDE 键盘布局的 Meta+Alt+K / L、面板循环的 Meta+Alt+P 清空后由 Krohnkite 使用，
桌面左右切换的重复 Meta+Ctrl+Left / Right 绑定清空。
Caps Lock 不切换 Rime 模式，也不提交预编辑。
应用内的 Ctrl+C / Ctrl+V、fish Ctrl+R 和 Rime 翻页 / 选词按键保留。

Ctrl+T 为桌面全局快捷键，执行 `kitten quick-access-terminal --detach`。
首次按下在屏幕顶部打开 25 行终端，再次按下隐藏，重新显示时保留 Shell 会话。
Home Manager 管理 `kitty/quick-access-terminal.conf`，沿用现有 kitty 字体和配色；
使用 `layer top` 兼容 Fcitx5 候选窗，关闭键盘抓取以保留全局快捷键。
该绑定优先于应用内同名快捷键。功能见
[kitty 官方文档](https://sw.kovidgoyal.net/kitty/kittens/quick-access-terminal/)。

更新后在新 Plasma 会话中验收，避免旧进程继续保留旧的全局快捷键。
声明层检查为 `scripts/verify/lvlv-desktop.nix`；实际操作与未通过项目见
[DESKTOP-ACCEPTANCE.md](DESKTOP-ACCEPTANCE.md)。

# lvlv 集成桌面验收（2026-10-03）

本轮将 MacTahoe KDE / GTK、Krohnkite、Firefox / VS Code 系统装饰、kitty、
Fcitx5 / Rime 和统一快捷键放进同一份配置，使用原有 `flake.lock` 构建。
`lvlv`、`lvlv.os`、`lvlv-vm` 完整求值通过；VM 完整构建及
`dry-activate`、`test`、`boot` 激活通过。实体机没有部署，物理磁盘没有改动。

最终冷启动系统：
`/nix/store/l3m5h6vmi1ag0vgwpwhwkkc12v18d2s5-nixos-system-lvlv-vm-26.11.20260928.7a0f122`。
KWin `ActiveState=active`、`NRestarts=0`。

| 验收项 | 结果与范围 |
| --- | --- |
| 格式、输入声明、lint | Alejandra、未声明 input 检查通过；Statix / Deadnix **48 / 0** |
| 组合配置 | 主题、平铺、终端、输入法与快捷键同一系统构建通过 |
| 冷启动 | WHPX / 原生 VirGL VM 启动最终配置；系统与用户失败服务为 0 |
| Qt / GTK / Firefox / Electron / kitty | 实际键盘输入 `nihao`，空格上屏“你好”；Electron 保存临时文件，kitty 写入临时文本 |
| 候选网格 | 125% 缩放下展开 / 收起、Page Up / Down、鼠标选词通过；保留原生 Wayland 候选定位 |
| 深浅皮肤 | 切换 KDE MacTahoeDark / Light，候选皮肤自动跟随；恢复浅色方案 |
| 动画 | 编译并启用 Wayland 候选显示 / 网格切换的 140ms 淡入；隐藏即时完成，未做原生动画逐帧一致性验收 |
| 快捷键 | Vicinae、kitty、Dolphin、CopyQ 实际启动 / 切换通过；清除 KDE 默认冲突 |
| 剪贴板 | Wayland 复制、粘贴与 CopyQ 内容一致 |
| LocalSend | Windows 测试客户端经 SSH 通道向真实 LocalSend 发送 1056 字节，接收文件 SHA-256 一致 |
| 音频 | 新增虚拟 HDA 声卡由 PipeWire 识别；不代表真实扬声器、麦克风或硬件编码验收 |
| OBS / Firefox 屏幕共享 | **未通过**：KDE 屏幕选择器在当前 VirGL 会话中不可见，日志有 `EGL_BAD_ALLOC`；没有把黑屏源或未启动的共享算作成功 |
| Flameshot | 完整截图已多次保存；交互截图入口在门户测试后超时，标注流程仍待复验 |
| 关机 / 原地重启 | **未通过**：来宾执行关机并卸载文件系统后，宿主 QEMU / WHPX 进程仍挂起；保留日志后停止已确认的隔离 VM 进程，再冷启动 |
| 实际多屏、局域网发现与实体机设备 | 未测试；当前 VM 只有一个虚拟显示输出，NAT 不验证 UDP 组播发现 |

LocalSend 接收文件 SHA-256：
`54db56976ab57e6b41e11b1d26e1cdff0877795dae91d6df4f742fbbbdc28e19`。
测试文件仅含生成的验收文字。没有发送个人文件，也没有连接其他人的设备。
协议依据 [LocalSend 官方协议](https://github.com/localsend/protocol)。

门户临时软件渲染诊断覆盖已删除。Krohnkite 排除 KDE 门户与 CopyQ 窗口，
避免把屏幕选择器、剪贴板工具当作普通应用铺满桌面；这不等于已修复 VirGL 捕获故障。
最终共享复测期间 `xdg-document-portal` 以退出码 21 结束，原始日志已保留；
重启该服务后恢复 active，清理测试后系统与用户失败服务再次为 0。
尚未确认该次退出的根因，不能据此将屏幕共享列为通过。
Qt 测试窗口、原生 GTK 小程序、浏览器本地测试页和 OBS 独立配置仅用于验收，
不会加入正式系统软件包或修改日常录制配置。

## 复验与回退

声明层检查：

```sh
nix eval --impure --json --file scripts/verify/lvlv-desktop.nix
```

它检查绑定唯一性、已清除的默认绑定、Wayland 输入前端、深浅候选设置，
并比较实体机与 VM 的快捷键和输入法包。
运行会话中的默认绑定由 `scripts/verify/lvlv-shortcuts-runtime.py` 读取实际
`kglobalshortcutsrc` 检查；最终会话 **137 个快捷键、0 冲突、0 缺失绑定**。
它使用 Python 标准库，应作为桌面用户运行。新 Plasma 会话启动后按
[SHORTCUTS.md](SHORTCUTS.md) 逐项操作。

VM 旧系统保留在 `/nix/var/nix/gcroots/lvlv-before-desktop-integration`，
更新前的输入法、桌面配置及 Rime 用户数据备份于
`/root/desktop-integration-results/user-config-before.tar.gz`。
需要临时返回旧版本时，在 VM 内执行：

```sh
sudo /nix/var/nix/gcroots/lvlv-before-desktop-integration/bin/switch-to-configuration test
```

该命令只切换当前运行系统；启动菜单仍可选择此前 generation。
旧闭包和激活程序已经检查保留，未执行实际回退演练。
Rime 用户学习数据继续可写，正常重建不清空 userdb。

证据位于本次 Windows 验证 workspace 的 `artifacts/desktop-*.png`、
`artifacts/desktop-localsend-transfer.json` 与 `artifacts/lvlv-whpx-desktop-integration-*`；
最终构建 / 激活 / 冷启动日志包为 `artifacts/desktop-integration-evidence.tar.gz`，
文档门户异常记录为 `artifacts/desktop-document-portal-test.log`。
VM 构建及激活日志位于 `/root/desktop-integration-results/`。
物理部署前必须补验共享 / 录屏、真实多屏、音频、LocalSend 局域网发现与重启稳定性。

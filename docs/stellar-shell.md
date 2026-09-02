# Stellar Shell — 工作计划

在 NixOS 上做一个精确模仿 macOS 的桌面。开发载体是一台 NixOS 虚拟机，**宿主
可以是 macOS 也可以是 Windows**，两者共用同一份 guest 配置。

本文档是计划，不是记录。已经落地的事实写在
[CLAUDE.md](../CLAUDE.md) 和 [scripts/vm/README.md](../scripts/vm/README.md)，
两处不一致时以那两处为准。

---

## 1. 产品是什么

```
Linux → Wayland → KineticWE（带原生平铺的 KWin 分支）
                    → Noctalia v5（Quickshell 壳）
                      → Stellar：Top Bar / Dock / Launcher / Overview /
                                 Control Center / Notifications / Design System
```

两件原创工作：

|                           | 内容                                             | 归属                    |
| ------------------------- | ------------------------------------------------ | ----------------------- |
| **`noctalia-appmenu`**    | 给 Noctalia 写 KWin AppMenu 后端                 | 走上游 PR，不留在本仓库 |
| **Stellar Design System** | 配色 / 字体 / 间距 / 动效的一套 token 与组件规范 | 本仓库                  |

**策略：不 fork Noctalia。** 用上游 + 主题 + 插件 + 配置 + 集成来组合。
这也正是 KineticWE 上游自己的做法 —— 它的 flake 直接把
`github:noctalia-dev/noctalia` 作为 input。

### 为什么必须是 KWin 系

目标是精确模仿 macOS，而 macOS 最标志性的是**全局菜单栏**。承载它的
`kde-appmenu` Wayland 协议**只有 KWin 系实现**。

所以 Hyprland 不是这个计划的简化版，是一个交付不了核心需求的不同计划。
这条约束曾经丢过一次（架构在对话里定完、搁置、然后一个 Hyprland 版的 VM
profile 被建出来又扔掉），现在它写在三个地方。

---

## 2. 宿主环境 —— macOS 与 Windows 通用

**不变量是 guest，不是 runner。** `nixosConfigurations.zaza-vm` 是一台普通的
`mkHost` 机器，不含任何宿主假设；每个平台只需要一个薄启动器。

### 平台对照

|                  | macOS（Apple Silicon）                                                 | Windows（x86_64）                                                                                   | Windows（arm64）             |
| ---------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ---------------------------- |
| 加速器           | `-accel hvf` ✅ 已实测                                                 | `-accel whpx`                                                                                       | `-accel whpx`                |
| 前置条件         | 无（`kern.hv_support=1`）                                              | 启用「Windows Hypervisor Platform」特性，Win10 2004+                                                | 同左                         |
| Guest 架构       | **aarch64-linux**                                                      | **x86_64-linux**                                                                                    | aarch64-linux                |
| 能否验证真机闭包 | ❌ 教室机是 x86_64                                                     | ✅ **同架构**                                                                                       | ❌                           |
| 固件             | `edk2-aarch64-code.fd` + `edk2-arm-vars.fd`（两个 pflash，已实测可用） | ⚠ **必须合成单文件** —— WHPX 用分离的 CODE/VARS 会崩                                                | 同左                         |
| 已知风险         | 无                                                                     | ⚠ qemu-project#934：Linux guest 在 WHPX + OVMF 下启动失败，关加速才引导。**上手第一件事就是验证它** | 同左 + WHPX/arm64 成熟度更低 |
| 启动器           | `scripts/vm/run.sh` ✅ 已有                                            | `scripts/vm/run.ps1` ⬜ 待写                                                                        | 同左                         |

Windows 侧的三条事实我**没有实测**（这台机器是 Mac），来自 QEMU 官方文档与
issue tracker。上手时逐条确认，与本表不符就改本表。

### Windows 的意外收益

Windows 多半是 x86_64，于是 guest 也是 x86_64-linux —— **和四台真实机器同架构**。
这台 VM 因此从「只能做与架构无关的 UI 工作」升级为「能验证真实闭包」。

实现上很便宜：`hosts/virtual/zaza-vm.nix` 已经是架构无关的
（`nixpkgs.hostPlatform` 由 `mkHost` 依 `system` 参数设定，host 文件里那行
冗余声明已删除并验证 drvPath 不变），所以只需在 `flake/hosts.nix` 的机器表里
再加一项、共用同一个 host 文件。

### 如果 QEMU 在 Windows 上走不通

按优先级的退路，全部**未验证**：

1. **VMware Workstation Pro** —— 个人使用已免费，Linux guest 的 3D 支持是这几个里最好的
2. **Hyper-V** —— 原生、性能好，但 Linux guest 只有合成视频，无 3D
3. **VirtualBox** —— VMSVGA 有有限的 3D
4. **[winq-emu](https://github.com/cmspam/winq-emu)** —— 打了 Venus/Vulkan GPU 加速的 Windows QEMU 分支，探索性

换 runner **不需要改 guest 配置** —— 这正是把 guest 声明进 flake 的意义。

### 图形加速的现状

两个平台都**还没有** 3D：

- macOS：Homebrew qemu 9.2.3 与 nixpkgs qemu 11.1.0 都没有 `virtio-gpu-gl`，
  也没链 virglrenderer（已逐一核实）
- Windows：未测

**但这不阻塞开发。** KWin 保留了软件合成后端
（`src/backends/drm/drm_qpainter_backend.cpp`，`KWIN_COMPOSE=Q` 选它）——
正是 Hyprland 连同 pixman 一起砍掉的那个。所以 KWin 能直接画在纯 2D 的
`virtio-gpu-pci` 上。动效调优阶段再考虑换能做 3D 的 runner。

---

## 3. 分期

每期末尾是可 falsify 的放行条件。

### Phase 0 — 宿主环境（两个平台各自跑通）

| #   | 任务                                                                | 平台            |
| --- | ------------------------------------------------------------------- | --------------- |
| 0.1 | ~~QEMU + HVF、固件、磁盘、ISO~~                                     | macOS ✅ 已完成 |
| 0.2 | 机器表加 `zaza-vm-x86`（`system = "x86_64-linux"`，共用 host 文件） | 共用            |
| 0.3 | 写 `scripts/vm/run.ps1` —— WHPX、合成单文件固件、同样的端口约定     | Windows         |
| 0.4 | 验证 qemu-project#934 在当前 QEMU 上是否仍然存在                    | Windows         |

**放行**：两个平台各自能从 ISO 引导到 NixOS 安装环境，且宿主能 `ssh -p 2222`
连进去。

### Phase 1 — 装机与第一次真实验证

装机流程见 [scripts/vm/README.md](../scripts/vm/README.md)（`disko-install`，
不用 nixos-anywhere，理由在那里）。

这一期的重点是**兑现那五条只过了求值、没实机跑过的东西**：

1. KineticWE 的 KWin 分支能否在 guest 上构建完（**无二进制缓存**，624 个 `.cpp`）
2. KWin 的 QPainter 后端能否在 `virtio-gpu-pci` 的 dumb buffer 上起来
3. greetd 自动登录进 `start-kineticwe` 后 `XDG_RUNTIME_DIR` / dbus 是否正确建立
4. QEMU 的 `-vnc` 能否拿到 virtio-gpu 的画面；`virtio-tablet` 指针位置是否对得上
5. Noctalia 是否随 session 一起起来

**放行**：浏览器打开 noVNC 能看到 Noctalia 的界面，并且点得动。

### Phase 2 — Noctalia 基线

先把**上游原样**跑起来，一行都不改。目的是建立"什么是上游行为"的基准，
否则后面分不清"我改坏了"和"上游本来如此"。

- 记录上游默认的组件、快捷键、配置文件位置
- 确认 Quickshell 的热重载在这个环境里可用（这决定迭代速度）
- 摸清 Noctalia 的插件机制边界：哪些能靠配置、哪些必须写插件

**放行**：一份"上游基线"记录进本文档；热重载可用。

### Phase 3 — `noctalia-appmenu`（核心原创工作之一）

给 Noctalia 写 KWin AppMenu 后端，让全局菜单栏真的出现。

- 摸清 `kde-appmenu` 协议与 KWin 侧的实现
- 客户端侧是 DBusMenu（`libdbusmenu` 在 nixpkgs 里，GTK 侧的
  `appmenu-gtk3-module` **不在** —— 这是个待解问题）
- 在 Noctalia 里实现后端，**走上游 PR**

**放行**：一个 Qt/KDE 应用和一个 GTK 应用的菜单都能出现在顶栏；PR 已提交。

> GTK 应用的全局菜单可能需要额外打包 `appmenu-gtk3-module`。这是本计划里
> 我目前最不确定的一环，Phase 2 结束时应当已经能判断它的难度。

### Phase 4 — Stellar Design System

配色 / 字体 / 间距 / 圆角 / 动效曲线的一套 token，加上组件规范。

本仓库已有 **stylix**（catppuccin-mocha），要决定的是：Stellar 的 token 是
stylix 的消费者，还是并行的另一套。倾向前者 —— 让桌面配色跟着系统主题走。

**放行**：token 定义落盘；至少两个组件按它渲染。

### Phase 5 — Stellar 各组件

Top Bar / Dock / Launcher / Overview / Control Center / Notifications。

顺序按"能不能独立验证"排，而不是按重要性：Top Bar 先（它承载 appmenu，
Phase 3 的成果直接体现在这里），Dock 次之，其余按需。

### Phase 6 — 落到真机

**顺序不可颠倒**：个人笔记本（x86_64）→ 泡若干天 → 教室机。

前置条件（全部来自 CLAUDE.md 的既有记录，与桌面无关但会一起生效）：

- `nix.gc.options` 从 `7d` 放宽、`grub.configurationLimit` 从 `1` 抬高 ——
  否则没有可回滚的 generation
- `boot.loader.grub.default = "3"` 是**菜单序号**，必须先读实机的
  `/boot/grub/grub.cfg` 查清它现在指向什么
- 走 `build → dry-activate → test → boot → switch` 阶梯。`test` 不碰引导器，
  拔电源即回退 —— 这是老师也能执行的恢复动作

---

## 4. 贯穿始终的约束

- **Windows 与 macOS 的 guest 配置必须是同一份。** 任何宿主特有的东西只能
  出现在 `scripts/vm/` 的启动器里，不能进 `hosts/` 或 `profiles/`。
- **drvPath 闸门。** 每次改动都验证四台 x86 机器 + darwin 的 drvPath 不变，
  除非改动本就针对它们。工具是 `scripts/verify/equiv.sh`。
- **lint 棘轮。** statix 48 / deadnix 0，只降不升（`scripts/verify/lint-ratchet.sh`）。
- **不确定的就不做**，但要把不确定写下来。
- **首次构建会编译整个 KWin。** KineticWE 无二进制缓存。6 GB 内存在链接 Qt 时
  偏紧，首次用 `ZAZA_VM_MEM=10240 ZAZA_VM_CPUS=6`。

---

## 5. 待决问题

| #   | 问题                                                                                                            | 何时需要答案             |
| --- | --------------------------------------------------------------------------------------------------------------- | ------------------------ |
| 1   | `inputs.kineticwe.inputs.nixpkgs.follows` 要不要加？现在**不加**（用上游自测组合），代价是闭包里可能两套 Qt/KDE | Phase 1 之后量过闭包大小 |
| 2   | GTK 应用的全局菜单需不需要打包 `appmenu-gtk3-module`？                                                          | Phase 3                  |
| 3   | Stellar token 是 stylix 的消费者还是并行体系？                                                                  | Phase 4                  |
| 4   | KineticWE 的平铺要不要用？它是选它的理由之一，但 appmenu 工作不依赖它                                           | Phase 2                  |
| 5   | Windows 上 QEMU 走不通时换哪个 runner？                                                                         | Phase 0.4 有结论后       |

# lvlv.os 硬件清单

扫描日期：2026-09-29。来源为当前 Windows 主机的 CIM / PnP 只读枚举。
这份清单用于准备 NixOS 配置；Windows 中识别到设备不代表已经验证 Linux 驱动。
不保存磁盘序列号、主板序列号、MAC 地址或其他唯一设备标识。

| 部件         | 扫描结果                                          | NixOS 配置 / 验证重点                                             |
| ------------ | ------------------------------------------------- | ----------------------------------------------------------------- |
| 主板 / 固件  | ASUS TUF GAMING B850-BTF WIFI W；BIOS 1681；UEFI  | 实体机使用 UEFI；尚未验证 Linux 启动、睡眠恢复和 Secure Boot 状态 |
| CPU          | AMD Ryzen 7 9800X3D，8 核 / 16 线程               | `common-cpu-amd`、AMD 微码、`kvm-amd`                             |
| 内存         | 24 GiB Lexar DDR5；Windows 报告配置速率 5600 MT/s | 不修改内存时序、EXPO 或 BIOS 设置                                 |
| 独立显卡     | AMD Radeon RX 6750 XT，PCI `1002:73df`            | `common-gpu-amd`、内核 `amdgpu`、Mesa；实体机测试输出接口与加速   |
| 集成显卡     | AMD Radeon Graphics，PCI `1002:13c0`              | 同样使用 `amdgpu`；不预设哪张 GPU 是主显示设备                    |
| SSD          | 1 TB J.ZAO 5 NVMe；控制器 PCI `1d97:5216`         | `nvme`、`common-pc-ssd` / 定期 TRIM；未选择安装分区               |
| 有线网络     | Realtek RTL8125，PCI `10ec:8125`                  | 内核 `r8169`；实机确认连接和协商速率                              |
| 无线网络     | Realtek RTL8922AE Wi-Fi 7，PCI `10ec:8922`        | 内核 `rtw89_8922ae`、可再分发固件；实机验证 AP 连接与恢复         |
| 蓝牙         | USB `13d3:3617`，Realtek 8922AE 系列              | 内核 `btusb` / Realtek 支持、固件、BlueZ；实机测试配对            |
| 声音         | Realtek HDA，codec `10ec:1168`；AMD HDMI 音频     | 内核 HDA 驱动、PipeWire；分别测试模拟和显示器音频                 |
| 当前区域设置 | Windows `en-US`；时区 `America/Denver`            | 桌面默认沿用；键盘实际布局仍需交互确认                            |

## 驱动选择

物理配置复用仓库锁定的 `nixos-hardware` 的 AMD CPU、AMD GPU 和 SSD 通用模块，
选择同一锁定 nixpkgs 中的 `linuxPackages_latest`，启用可再分发固件。
没有加入未经实测的 PCIe / IOMMU / 电源管理绕过参数，也没有为网卡添加树外驱动。

RTL8922AE 的 `10ec:8922` 已包含在 Linux 6.12 的
[rtw89_8922ae 设备表](https://github.com/torvalds/linux/blob/v6.12/drivers/net/wireless/realtek/rtw89/rtw8922ae.c)；
蓝牙 `13d3:3617` 已包含在同版本的
[btusb Realtek 设备表](https://github.com/torvalds/linux/blob/v6.12/drivers/bluetooth/btusb.c)。
这支持优先使用内核驱动的选择，但不证明本机 Wi-Fi 7 的每项功能、蓝牙配对或睡眠恢复已通过测试。

## 存储边界

没有从 Windows 推断可供安装的 Linux 分区，也没有格式化或重新分区任何实体磁盘。
`default.nix` 中的挂载点是明确的占位约定：

- `/`：`/dev/disk/by-label/lvlv-root`，ext4。
- `/boot`：`/dev/disk/by-label/lvlv-boot`，FAT EFI System Partition。
- 没有实体 swap 分区、交换文件、LUKS 或休眠配置。

这些标签并非扫描到的现有标签；不要据此直接向当前 Windows SSD 安装。
QEMU 验证使用独立的虚拟磁盘和 VM 硬件模块，不能把 VM 的设备名或 UUID 搬到实体机。

实体安装准备阶段应先启动 NixOS 安装介质，读取 `lsblk -f`、`lspci -nnk`、`lsusb`、
`findmnt` 和内核日志；在确认目标磁盘、分区方案并挂载目标根目录后，运行
`nixos-generate-config --root /mnt --show-hardware-config`，把实际挂载信息合并进
`hardware-configuration.nix`，并移除 `default.nix` 中的占位挂载配置。
保留上述 AMD / 固件模块；按实测确认或替换 initrd 模块列表。

## 验证范围

QEMU 可以验证 x86_64 系统构建、UEFI 启动、KDE 登录与基本桌面行为。
QEMU 的 VirtIO 显卡、网络、磁盘与模拟音频不能验证这台机器的 AMD GPU、RTL8922AE、
RTL8125、蓝牙、NVMe 控制器、板载音频或睡眠恢复；这些项目保留为实体机启动后的验证。

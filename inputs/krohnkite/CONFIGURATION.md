# 文件配置

Krohnkite 使用 KDE 原生 KConfig。当前用户的配置文件是
`${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc`，脚本设置放在
`[Script-krohnkite]`。安装重写版后，原有同组配置继续使用。
KWin 打开 `kwinrc`，按插件 ID 选择 `Script-<插件 ID>`，QML 的
`KWin.readConfig` 从该组读取值。参见 [KWin 配置入口](https://github.com/KDE/kwin/blob/Plasma/6.7/src/main.cpp)
和 [脚本配置实现](https://github.com/KDE/kwin/blob/Plasma/6.7/src/scripting/scripting.cpp)。

## 编辑与生效

在现有 `kwinrc` 中合并需要的键；不要用示例覆盖整个文件。也可以用 KDE
命令行工具逐项修改：

```sh
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapLeft 8
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapRight 8
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapTop 8
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapBottom 8
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapBetween 8
kwriteconfig6 --file kwinrc --group Script-krohnkite --key noTileBorder --type bool true
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
```

以上命令在正在运行 Plasma 的用户会话中执行。`kwriteconfig6` 修改文件，
最后一条命令让 KWin 重读文件。手动编辑后也执行同一条 `reconfigure`。
设置重载在现有会话中完成；更换 Krohnkite 包或 JavaScript 后，退出并重新登录
Plasma，让新会话加载新包。
可用 `kreadconfig6 --file kwinrc --group Script-krohnkite --key screenGapLeft`
检查磁盘值。[KDE 写配置工具](https://github.com/KDE/kconfig/blob/master/src/kreadconfig/kwriteconfig.cpp)
提供 `--file`、`--group`、`--key`、`--type bool` 和 `--delete`。

KWin 的 `readConfig` 读取内存中的配置；周期调用它不会主动重读磁盘。
`reconfigure` 重读 `kwinrc` 后发送配置变更信号，脚本在 100ms 防抖后刷新。
相同的解码结果不会重复应用，失败的读取保留上一份有效配置。
现有窗口的间距、浮动匹配和忽略规则可以这样更新，无需卸载脚本，用户手动选择
的浮动状态继续保留。已有浮动窗口缓存的尺寸与位置也会保留，`floatConfig` 的
尺寸和位置设置用于首次建立浮动位置的窗口。
`layoutPerDesktop`、`layoutPerActivity` 不变时，已选择的布局继续保留；改变这两个
设置可能为新的分组建立布局状态。布局顺序和默认布局设置用于后续布局选择或
新建的布局状态。
参见 [KWin 重读流程](https://github.com/KDE/kwin/blob/Plasma/6.7/src/workspace.cpp)
和 [D-Bus reconfigure 接口](https://github.com/KDE/kwin/blob/Plasma/6.7/src/org.kde.KWin.xml)。

## 基本示例

以下内容也保存在 [示例文件](packages/config/examples/kwinrc)：

```ini
[Plugins]
krohnkiteEnabled=true

[Script-krohnkite]
screenGapLeft=8
screenGapRight=8
screenGapTop=8
screenGapBottom=8
screenGapBetween=8
layoutPerDesktop=true
layoutPerActivity=true
noTileBorder=false
monocleMaximize=true
monocleMinimizeRest=false
floatingClass=org.kde.systemsettings,pavucontrol
floatingTitle=Picture-in-Picture
notificationDuration=1000
```

`[Plugins]` 控制已安装脚本的启用状态，`[Script-krohnkite]` 控制脚本行为。
删掉某个设置键，再执行 `reconfigure`，该键会使用内置默认值。
缺省键不会覆盖已有 KDE 配置。所有 145 个键与默认值见
[配置源](packages/config/src/defaults.ts)，其来源是固定版本上游的 `res/config.xml`。

| 设置 | 格式与含义 |
| --- | --- |
| `screenGapLeft/Right/Top/Bottom/Between` | 非负数字，逻辑像素 |
| `layoutPerDesktop`、`layoutPerActivity`、`noTileBorder` | `true` 或 `false` |
| `floatingClass`、`ignoreClass` | 逗号分隔，精确匹配窗口类或资源名 |
| `tilingClass` | 逗号分隔，精确匹配窗口类 |
| `floatingTitle`、`ignoreTitle` | 逗号分隔，标题包含其中一项即匹配 |
| `ignoreScreen`、`ignoreVDesktop`、`ignoreActivity` | 逗号分隔；输出名、桌面名、活动标识或名称依宿主提供的值匹配 |
| `tileLayoutOrder` 等 `*LayoutOrder` | `1` 到 `12` 排序，`0` 禁用；全部禁用时回退 Tile |
| `soleWindowWidth/Height`、`floatDefaultWidth/Height` | 百分比，限制在 `1` 到 `100` |
| `notificationDuration` | 毫秒；`0` 隐藏布局提示 |

保留内置忽略规则时不要直接用短列表替换 `ignoreClass`；设置这个键会替换整个
列表。快捷键的实际按键绑定由 Plasma 快捷键设置管理；`shortcutConf` 定义
现有 Krohnkite 快捷键处理器的动作或序列。

## 多行规则

`gapsOverrideConfig`、`floatConfig`、`shortcutConf` 等复杂设置按行读取，每行
内部的逗号仍属于该条规则。KConfig 在文件中用 `\n` 表示换行，原生读取后
交给配置模块的是实际换行。例子：

```ini
[Script-krohnkite]
gapsOverrideConfig=DP-1:left=12,right=12,between=8\nHDMI-A-1:between=6
floatConfig=org.kde.systemsettings:width=60,height=70\npavucontrol:width=40,height=60
shortcutConf=FocusNextSC:ma=FocusNext,ra=SetMonocleLayout\nFocusLeftSC,FocusRightSC:ma=ToggleFloatAll,st=450
```

使用 Bash 写多行值时，让 KDE 工具处理转义：

```sh
kwriteconfig6 --file kwinrc --group Script-krohnkite --key gapsOverrideConfig \
  $'DP-1:left=12,right=12,between=8\nHDMI-A-1:between=6'
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
```

将 `DP-1`、`HDMI-A-1` 和窗口类替换为本机名称。空行以及以 `#` 开头的规则行
会被忽略。文件中的换行转义由 [KConfig INI 实现](https://github.com/KDE/kconfig/blob/master/src/core/kconfigini.cpp)
处理，运行时无需额外的文件解析器。

## 无效值与读取错误

配置模块按照默认值的类型解码，有限数字字符串可转换为数字，非法类型、
空数字字符串、`NaN` 和无穷值回退该键默认值。负间距被限制为零；上述百分比
有上下限。`monocleMinimizeRest=true` 会关闭 `preventMinimize`，避免行为冲突。
未知键不参与布局。复杂规则中无法识别的动作或非法参数会被对应规则处理器忽略。
宿主直接返回的字符串列表也被保留；非字符串或混合类型的数组回退该键默认值。
多行规则列表中的逗号属于单条规则，不会被再次拆分。

如果宿主读取配置抛出异常，日志包含 `readConfig` 操作与原因，运行中的配置
保持不变；修复后再次执行 `reconfigure` 即可重试。系统设置的 Krohnkite 页面
与手动文件配置使用同一份 KConfig 数据。

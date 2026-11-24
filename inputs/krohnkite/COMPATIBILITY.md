# 上游兼容性

对照 `.repo/krohnkite` 固定提交 `ade1de7488cd84185f6f14efd4fba8e8b0db7ddb`。
保留原插件 ID、145 个配置默认值、39 个快捷键名称及配置界面。
配置键存在不代表其所有高级行为已经与上游完全一致。

## 已验证

- 十二种布局；216 组直接从固定上游源码生成的布局基准，覆盖窗口数量、间距与旋转，允许 1px 整数舍入差异。
- 窗口规则、浮动与 Dock、屏幕/桌面状态、容量溢出、配置重载。
- 快捷键序列的最长匹配、前缀超时回退、持续模式、定时器清理。
- Dock 拖放、交换、移出、固定槽位、尺寸调整与预览；Columns 的拖放插入。
- Effect 服务、同步事件队列、每扇窗口的独立 Scope、异常报告和信号断开。
- 真实 Qt 的启动、平铺、Monocle、配置重载与卸载；独立 KWin/Wayland 会话中的双窗口平铺、Monocle 切换、同一 URL 连续加载与卸载两轮。
- 卸载时还原脚本更改过的边框、层级、最大化与最小化状态；保留窗口原始最大化轴。

## 当前差异

以下配置保留在界面及解析结果中，行为暂时简化，不能视为完整上游兼容：

| 配置/行为 | 当前实现 |
| --- | --- |
| `floatRandomEnable`、`floatRandomWidth`、`floatRandomHeight` | 使用确定性的浮动尺寸和位置；未实现随机放置 |
| `floatConfig` 的 `auto` / `a` | 应用规则初始位置；未持续重新定位 |
| `soleWindowOutputOverride` | 使用普通单窗口布局配置 |
| `focusNormal`、`focusMeta` | 在受管理窗口中选择焦点，特殊窗口选择策略未完整移植 |
| `focusMoveVDesktopsNormal`、`focusMoveVDesktopsMeta` | 常规焦点/移动；尚未完整实现跨虚拟桌面策略 |
| `srfToScreenOrderLeft/Top/Right/Bottom`、`srfToVDesktopOrderLeft/Top/Right/Bottom` | 可以迁移容量溢出的窗口；方向性路由顺序尚未完整移植 |
| `unfitGreater`、`unfitLess` | 尊重窗口最小/最大尺寸；未实现不可平铺时自动浮动 |
| `srfDefineCfg` | 多输出列表使用 OR 匹配；尚未选择首个在线输出作为优先标签 |
| `log*` | 保留运行时错误报告；高级日志类别过滤未移植 |
| Dock 相对边缘尺寸协商 | 有边缘预留；最小尺寸协商及两侧合计不超过 50% 的策略简化 |
| Columns 隐藏空列与键盘移动 | 支持拖放列数限制；隐藏空列复用及键盘移动的全部列限制策略简化 |

运行时不使用 Effect 异步平台、网络和纳秒时钟。Qt 没有 BigInt，相关初始化被延迟；
如果调用这些未支持的功能会明确报错，未使用浮点数模拟 BigInt。

KWin 集成测试使用独立虚拟显示和 D-Bus 会话，不热切换用户桌面的原脚本。
这是为了隔离原脚本卸载后残留的回调与 KWin 脚本 ID 重用；不能据此断言所有桌面热加载场景均已验证。

# MiniMaxMenuBar 架构文档

## 1. 项目概述

**项目名称**: MiniMaxMenuBar
**项目类型**: macOS 菜单栏应用 (MenuBar App)
**核心功能**: 在 macOS 状态栏显示 MiniMax API 剩余配额百分比
**技术栈**: SwiftUI + AppKit (NSStatusItem/NSPopover)
**最低 macOS 版本**: macOS 14.0+

## 2. 架构模式

采用 **MVVM (Model-View-ViewModel)** 架构：

```
┌─────────────────────────────────────────────────────────────┐
│                        View Layer                           │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │  AppDelegate    │    │  ContentView (SwiftUI)         │ │
│  │  (NSPopover)    │    │  - Settings Form                │ │
│  └────────┬────────┘    │  - Quota Card                   │ │
│           │             │  - Action Buttons               │ │
└───────────┼─────────────┴─────────────────────────────────┘
            │
┌───────────┼───────────────────────────────────────────────┐
│           │           ViewModel Layer                      │
│           ▼                                               │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  StatusBarViewModel (ObservableObject)              │  │
│  │  - quota: ModelRemain?                              │  │
│  │  - errorMessage: String?                             │  │
│  │  - isLoading: Bool                                  │  │
│  │  - refresh()                                        │  │
│  │  - startAutoRefresh()                               │  │
│  └───────────────────────┬─────────────────────────────┘  │
└──────────────────────────┼─────────────────────────────────┘
                           │
┌──────────────────────────┼─────────────────────────────────┐
│                          │       Service Layer             │
│                          ▼                                 │
│  ┌───────────────────────┐  ┌───────────────────────────┐ │
│  │  ConfigService        │  │  QuotaService             │ │
│  │  - UserDefaults 存储   │  │  - fetchQuota() async     │ │
│  │  - apiKey 管理         │  │  - URLSession 请求        │ │
│  │  - groupId 管理        │  │  - JSON 解析              │ │
│  └───────────────────────┘  └───────────────────────────┘ │
│                          │                                 │
│  ┌───────────────────────┐  ┌───────────────────────────┐ │
│  │  UsageTracker         │  │  StatusBarViewModel       │ │
│  │  - 快照记录/计算       │  │  - 状态管理               │ │
│  │  - 数据清理            │  │  - refresh()              │ │
│  └───────────────────────┘  └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────┼─────────────────────────────────┐
│                          │       Model Layer                │
│                          ▼                                 │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  QuotaModels.swift                                   │  │
│  │  - APIResponse                                       │  │
│  │  - BaseResp                                         │  │
│  │  - ModelRemain (计算属性: usagePercentage, etc.)    │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 3. 目录结构

```
MiniMaxMenuBar/
├── Sources/                      # 源代码目录
│   ├── main.swift                # 应用入口，手动启动 NSApplication
│   ├── AppDelegate.swift         # NSApplicationDelegate，处理状态栏和 Popover
│   ├── App.swift                 # @main 入口 (实际未使用，用 main.swift 替代)
│   ├── StatusBarViewModel.swift  # 视图模型，管理状态和刷新逻辑
│   ├── ContentView.swift         # SwiftUI 视图 (包含在 App.swift 中)
│   ├── QuotaService.swift        # API 请求服务
│   ├── ConfigService.swift       # 配置管理服务
│   └── UsageTracker.swift       # 使用量追踪服务 (新增)
├── Shared/                       # 共享代码目录
│   └── QuotaModels.swift         # 数据模型定义
├── Resources/                    # 资源目录
│   ├── Info.plist                # 应用配置
│   └── MiniMaxMenuBar.entitlements # 权限配置
├── project.yml                   # XcodeGen 配置
├── MiniMaxMenuBar.xcodeproj/     # Xcode 项目文件
└── scripts/                      # 构建脚本
    └── build_dmg.sh
```

## 4. 核心组件

### 4.1 main.swift
应用入口点，手动启动 NSApplication：
- 创建 NSApplication 实例
- 设置 AppDelegate
- 设置 accessory 启动策略 (`setActivationPolicy(.accessory)`)

### 4.2 AppDelegate.swift
负责菜单栏 UI 和生命周期管理：
- `setupStatusItem()`: 创建 NSStatusItem 按钮
- `setupPopover()`: 配置 NSPopover
- `setupEventMonitor()`: 全局点击事件监控，关闭 popover
- `bindViewModel()`: 绑定 ViewModel 状态到 UI
- `updateStatusBar()`: 更新状态栏文本
- `togglePopover()`: 切换 popover 显示/隐藏

### 4.3 StatusBarViewModel.swift
核心业务逻辑管理：
- 单例模式 (`shared`)
- `@Published` 属性用于 SwiftUI 绑定
- `refresh()`: 手动刷新配额数据
- `startAutoRefresh()`: 每 300 秒自动刷新
- `statusBarText`: 状态栏显示文本 (N/A, !, XX%, ...)
- `statusBarIcon`: 状态栏图标 (颜色指示)

### 4.4 QuotaService.swift
API 请求封装：
- `fetchQuota()`: 异步获取配额数据
- 错误类型：`notConfigured`, `requestFailed`, `parseFailed`, `apiError`
- 使用 URLSession 发送 GET 请求
- Bearer Token 认证

### 4.5 ConfigService.swift
配置持久化管理：
- 使用 UserDefaults 存储
- `apiKey`: MiniMax API Key
- `groupId`: 可选的 Group ID
- `isConfigured`: 配置状态检查
- `clear()`: 清除所有配置

### 4.6 QuotaModels.swift
数据模型定义：
```swift
APIResponse     // API 响应根对象
BaseResp        // 基础响应 (statusCode, statusMsg)
ModelRemain     // 模型配额信息
DailySnapshot   // 每日配额快照 (用于使用量统计)
```

**注意**: API 返回的 `xxxUsageCount` 字段表示**剩余可用配额**，非已使用量。

### 4.7 ContentView (in App.swift)
SwiftUI 视图组件：
- **设置表单**: API Key 和 Group ID 输入
- **配额卡片**: 显示模型名称、时间窗口、统计数据
- **统计视图**: 每日/每周使用量柱状图
- **错误卡片**: 显示错误信息
- **加载视图**: 加载状态
- **操作按钮**: 刷新、退出

### 4.8 UsageTracker.swift
使用量追踪服务：
- `recordSnapshot()`: 记录当天配额快照
- `getDailyUsage(for:)`: 计算指定日期使用量
- `getWeeklyUsage()`: 获取近7天使用量
- `cleanupOldData()`: 清理30天前旧数据
- 存储: UserDefaults Key `USAGE_SNAPSHOTS`
- 容量: ~1.5KB (30天数据)

### 4.9 StatsView (in App.swift)
统计视图组件：
- 本周已用/总配额显示
- 近7天柱状图
- 日均和最大使用量

## 5. 数据流

```
用户点击状态栏
       │
       ▼
AppDelegate.togglePopover()
       │
       ▼
StatusBarViewModel.refresh() ──────► QuotaService.fetchQuota()
       │                                    │
       │                                    ▼
       │                            URLSession GET
       │                            (Authorization: Bearer)
       │                                    │
       │◄───────────────────────────────────┘
       │
       ▼
@Published quota/errorMessage 更新
       │
       ▼
SwiftUI 视图自动更新
```

## 6. 状态栏显示规则

| 状态 | 显示内容 |
|------|----------|
| 未配置 API Key | `N/A` |
| 请求出错 | `⚠️` |
| 加载中 | `...` |
| 正常 | `XX%` (剩余百分比) |

图标颜色：
- `🟢` 剩余 > 70%
- `🟡` 剩余 30-70%
- `🔴` 剩余 < 30%

## 7. API 集成

- **Endpoint**: `https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains`
- **Method**: GET
- **Headers**: `Authorization: Bearer <API_KEY>`
- **可选参数**: `GroupId` (Query String)
- **超时**: 15 秒

## 8. 刷新策略

1. **启动时**: 立即刷新
2. **自动刷新**: 每 300 秒 (5 分钟)
3. **手动刷新**: 点击刷新按钮
4. **打开 Popover 时**: 每次打开都刷新

## 9. 构建配置

- **Bundle ID**: `com.minimax.menubar`
- **版本**: 1.0.0
- **代码签名**: 手动签名，无签名 (调试模式)
- **入口**: `LSUIElement = true` (隐藏 Dock 图标)

## 10. 开发规范

### 代码修改原则

**每次非文档修改后，必须确保编译测试通过。**

| 修改类型 | 示例 | 需要编译测试 |
|----------|------|-------------|
| 文档修改 | .md 文档 | ❌ 不需要 |
| 代码修改 | .swift 文件 | ✅ 必须 |
| 配置修改 | project.yml, Info.plist | ✅ 必须 |
| 资源修改 | 图片、脚本等 | ✅ 必须 |

### 编译测试检查清单

- [ ] `xcodebuild build` 编译成功
- [ ] 无编译警告 (warnings)
- [ ] 应用能正常启动
- [ ] 核心功能运行正常

### 流程

```
代码/配置/资源修改
        │
        ▼
    编译测试
        │
    ┌───┴───┐
    │       │
  失败    成功
    │       │
  修复    结束
    │
    ▼
重复编译测试
```

### 临时文件清理

**项目目录下**或**/tmp下**产生的临时文件（非最终需要的），开发完成后必须清理。

| 类型 | 处理方式 |
|------|----------|
| 测试用的临时文件 | 删除 |
| 临时构建产物 | 删除 |
| 调试用的输出文件 | 删除 |
| 临时分支/Worktree | 如不需要则删除 |

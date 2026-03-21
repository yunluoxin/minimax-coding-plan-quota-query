# MiniMaxMenuBar 开发计划

## 目标
在 macOS 状态栏显示 MiniMax API 剩余配额百分比（类似 WiFi、音量图标）。

## 技术方案
- **框架**: SwiftUI (macOS 14+)
- **状态栏**: `MenuBarExtra`
- **API 请求**: URLSession，模仿 Go 代码实现
- **配置**: 环境变量

## 项目结构

```
MiniMaxMenuBar/
├── Sources/
│   ├── main.swift           # 手动启动 NSApplication
│   ├── App.swift            # @main + MenuBarExtra
│   ├── QuotaService.swift   # API 请求逻辑
│   └── ConfigService.swift  # 环境变量读取
├── Shared/
│   └── QuotaModels.swift    # 复用现有模型
├── Resources/
│   └── Info.plist
└── project.yml              # XcodeGen 配置
```

## API 信息

| 项目 | 值 |
|------|-----|
| **URL** | `https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains` |
| **方法** | `GET` |
| **认证** | `Authorization: Bearer <API_KEY>` |
| **参数** | `GroupId` (可选, Query String) |

## 环境变量

| 变量名 | 说明 |
|--------|------|
| `MINIMAX_API_KEY` | MiniMax API Key |
| `MINIMAX_GROUP_ID` | Group ID（可选） |

## 数据模型

```swift
struct APIResponse: Codable {
    let modelRemains: [ModelRemain]
    let baseResp: BaseResp
}

struct ModelRemain: Codable {
    let modelName: String
    let currentIntervalTotalCount: Int
    let currentIntervalUsageCount: Int
    let remainsTime: Int64
    let startTime: Int64
    let endTime: Int64
    let currentWeeklyTotalCount: Int
    let currentWeeklyUsageCount: Int
    let weeklyRemainsTime: Int64

    var remainingCount: Int { currentIntervalTotalCount - currentIntervalUsageCount }
    var usagePercentage: Double { ... }
    var resetDateFormatted: String { ... }
}
```

## UI 设计

### 状态栏图标
- 显示文字: `78%`（剩余百分比）
- 无 API Key 时显示: `N/A`
- 请求失败时显示: `!`

### 点击菜单
```
┌─────────────────────────┐
│ MiniMax Quota            │
├─────────────────────────┤
│ GPT-4o                   │
│ 已用: 220/1000           │
│ 剩余: 780                │
│                          │
│ 窗口重置: 2024-03-22 UTC │
├─────────────────────────┤
│ ↻ 刷新                   │
│ 退出                     │
└─────────────────────────┘
```

## 实现步骤

| 步骤 | 文件 | 内容 |
|------|------|------|
| 1 | `project.yml` | XcodeGen 配置 |
| 2 | `Resources/Info.plist` | 应用信息 |
| 3 | `Shared/QuotaModels.swift` | 数据模型 |
| 4 | `Sources/ConfigService.swift` | 环境变量读取 |
| 5 | `Sources/QuotaService.swift` | API 请求 |
| 6 | `Sources/App.swift` | @main + MenuBarExtra + ViewModel |
| 7 | `Sources/main.swift` | 手动启动应用 |

## 关键实现细节

### 刷新策略
- 启动时立即刷新
- 每 60 秒自动刷新
- 手动点击刷新按钮

### 错误处理
- 无 API Key: 状态栏显示 "N/A"
- 请求失败: 状态栏显示 "!"，菜单显示错误信息
- 数据解析失败: 状态栏显示 "?"

### 构建命令
```bash
cd MiniMaxMenuBar
xcodegen generate
open MiniMaxMenuBar.xcodeproj
```

### project.yml scheme 配置
```yaml
schemes:
  MiniMaxMenuBar:
    build:
      targets:
        MiniMaxMenuBar: all
```

### 运行前配置环境变量（Xcode 中）
```
MINIMAX_API_KEY=your_api_key
MINIMAX_GROUP_ID=your_group_id
```

## 注意事项
- 不使用 Widget，仅原生 SwiftUI MenuBarExtra
- 只显示第一个模型的配额
- 本地调试无需签名

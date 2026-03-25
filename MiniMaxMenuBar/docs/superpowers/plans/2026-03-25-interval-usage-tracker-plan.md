# Interval Usage Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用窗口数据替代已删除的周用量字段，实现每日/每周用量统计

**Architecture:** 
- SwiftData 存储 IntervalSnapshot（每次刷新存一条）+ DailySnapshot（冗余优化）
- 窗口规则：每5小时一个窗口，每天5个窗口（0-5点、5-10点、10-15点、15-20点、20-24点）
- 窗口用量 = 该窗口最后一条记录的 usageCount

**Tech Stack:** SwiftData, SwiftUI, AppKit (hybrid menu bar app)

---

## File Structure

| 文件 | 职责 |
|------|------|
| `Shared/QuotaModels.swift` | 新增 IntervalSnapshot, DailySnapshot SwiftData Models；删除旧的 DailySnapshot struct |
| `Sources/AppDelegate.swift` | 配置 SwiftData ModelContainer |
| `Sources/UsageTracker.swift` | 核心统计逻辑：记录快照、计算日/周用量（异步 API） |
| `Sources/StatusBarViewModel.swift` | 调用新 recordSnapshot 接口 |
| `Sources/App.swift` | StatsView 使用 @Query 直接绑定 SwiftData |

---

## Task 1: 添加 SwiftData Models 并删除旧结构

**Files:**
- Modify: `Shared/QuotaModels.swift`

- [ ] **Step 1: 读取现有 DailySnapshot 位置**

```bash
grep -n "struct DailySnapshot" Shared/QuotaModels.swift
```

确认旧的 `DailySnapshot` struct 行号（大约在第60行）

- [ ] **Step 2: 在文件末尾添加 SwiftData Models**

在 `Shared/QuotaModels.swift` 末尾添加：

```swift
import SwiftData

@Model
final class IntervalSnapshot {
    @Attribute(.unique) var id: String          // "\(date)_\(intervalIndex)_\(timestamp.timeIntervalSince1970)"
    var date: String                            // "yyyy-MM-dd" 本地时间
    var intervalIndex: Int                      // 0-4
    var totalCount: Int                         // currentIntervalTotalCount
    var usageCount: Int                        // 窗口已用量
    var timestamp: Date                        // 本地记录时间
    var startTime: Int64                       // API 原始 UTC
    var endTime: Int64                         // API 原始 UTC

    init(date: String, intervalIndex: Int, totalCount: Int, usageCount: Int, timestamp: Date, startTime: Int64, endTime: Int64) {
        self.id = "\(date)_\(intervalIndex)_\(timestamp.timeIntervalSince1970)"
        self.date = date
        self.intervalIndex = intervalIndex
        self.totalCount = totalCount
        self.usageCount = usageCount
        self.timestamp = timestamp
        self.startTime = startTime
        self.endTime = endTime
    }
}

@Model
final class DailySnapshot {
    @Attribute(.unique) var date: String       // "yyyy-MM-dd"
    var dailyTotal: Int                        // 当日总用量
    var weeklyTotal: Int                       // 本周总用量
    var timestamp: Date

    init(date: String, dailyTotal: Int, weeklyTotal: Int, timestamp: Date) {
        self.date = date
        self.dailyTotal = dailyTotal
        self.weeklyTotal = weeklyTotal
        self.timestamp = timestamp
    }
}
```

- [ ] **Step 3: 删除旧的 DailySnapshot struct**

用 Edit 工具删除旧的 `DailySnapshot` struct（大约在第60行）

- [ ] **Step 4: 提交**

```bash
git add Shared/QuotaModels.swift
git commit -m "feat: replace DailySnapshot UserDefaults struct with SwiftData @Model"
```

---

## Task 2: 配置 SwiftData ModelContainer

**Files:**
- Modify: `Sources/AppDelegate.swift`
- Modify: `Sources/App.swift`

**Context:** App 是 AppKit + SwiftUI hybrid，需在 NSHostingController 传入 modelContainer

- [ ] **Step 1: 在 AppDelegate 添加 ModelContainer**

在 `AppDelegate` 类中添加属性：

```swift
static var modelContainer: ModelContainer = {
    let schema = Schema([IntervalSnapshot.self, DailySnapshot.self])
    let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

- [ ] **Step 2: 修改 setupPopover() 传入 modelContainer**

修改 `AppDelegate.setupPopover()`：

```swift
private func setupPopover() {
    popover = NSPopover()
    popover.contentSize = NSSize(width: 320, height: 320)
    popover.behavior = .transient
    popover.animates = true
    let contentView = ContentView(viewModel: viewModel)
        .modelContainer(AppDelegate.modelContainer)
    popover.contentViewController = NSHostingController(rootView: contentView)
}
```

- [ ] **Step 3: 提交**

```bash
git add Sources/AppDelegate.swift Sources/App.swift
git commit -m "feat: configure SwiftData ModelContainer in AppDelegate"
```

---

## Task 3: 重写 UsageTracker（异步 API）

**Files:**
- Modify: `Sources/UsageTracker.swift`

**关键变更：** 查询方法改为 async，返回值通过 completion handler 或直接 await 获取

- [ ] **Step 1: 重写 UsageTracker 使用 SwiftData**

替换整个 `Sources/UsageTracker.swift`：

```swift
import Foundation
import SwiftData

class UsageTracker {
    static let shared = UsageTracker()
    
    private let maxDays = 30
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 记录窗口快照（每次API刷新时调用）
    func recordSnapshot(model: ModelRemain) {
        let dateString = Self.dateString(from: model.startTime)
        let intervalIndex = Self.intervalIndex(from: model.startTime)
        let timestamp = Date()
        
        let snapshot = IntervalSnapshot(
            date: dateString,
            intervalIndex: intervalIndex,
            totalCount: model.currentIntervalTotalCount,
            usageCount: model.currentIntervalUsageCount,
            timestamp: timestamp,
            startTime: model.startTime,
            endTime: model.endTime
        )
        
        Task { @MainActor in
            let context = AppDelegate.modelContainer.mainContext
            context.insert(snapshot)
            try? context.save()
            self.cleanupOldDataIfNeeded()
        }
    }
    
    /// 计算指定日期的日用量（异步）
    func dailyUsage(for date: Date) async -> Int {
        let dateString = Self.dateString(from: date)
        
        return await MainActor.run {
            let context = AppDelegate.modelContainer.mainContext
            let descriptor = FetchDescriptor<IntervalSnapshot>(
                predicate: #Predicate { $0.date == dateString }
            )
            let snapshots = (try? context.fetch(descriptor)) ?? []
            
            // 按 intervalIndex 分组，取每组最大 usageCount
            var maxByInterval: [Int: Int] = [:]
            for snap in snapshots {
                if let existing = maxByInterval[snap.intervalIndex] {
                    if snap.usageCount > existing {
                        maxByInterval[snap.intervalIndex] = snap.usageCount
                    }
                } else {
                    maxByInterval[snap.intervalIndex] = snap.usageCount
                }
            }
            
            var total = 0
            for i in 0..<5 {
                total += maxByInterval[i] ?? 0
            }
            return total
        }
    }
    
    /// 计算近7天每日用量（异步）
    func last7DaysUsage() async -> [(date: Date, usage: Int)] {
        var result: [(Date, Int)] = []
        let calendar = Calendar.current
        
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let usage = await dailyUsage(for: date)
            result.append((date, usage))
        }
        
        return result
    }
    
    /// 计算周用量（异步）
    func weeklyUsage() async -> Int {
        var total = 0
        let calendar = Calendar.current
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            total += await dailyUsage(for: date)
        }
        
        return total
    }
    
    // MARK: - Private Methods
    
    /// 根据 UTC startTime 计算本地日期字符串
    private static func dateString(from startTime: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(startTime) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    /// 根据 UTC startTime 计算窗口序号
    private static func intervalIndex(from startTime: Int64) -> Int {
        let date = Date(timeIntervalSince1970: TimeInterval(startTime) / 1000)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 0...4: return 0   // 0-5点
        case 5...9: return 1   // 5-10点
        case 10...14: return 2 // 10-15点
        case 15...19: return 3 // 15-20点
        case 20...23: return 4 // 20-24点
        default: return 0
        }
    }
    
    /// 清理旧数据（首次插入时调用）
    private func cleanupOldDataIfNeeded() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
        let cutoffString = Self.dateString(from: Int64(cutoffDate.timeIntervalSince1970 * 1000))
        
        let context = AppDelegate.modelContainer.mainContext
        let descriptor = FetchDescriptor<IntervalSnapshot>(
            predicate: #Predicate { $0.date < cutoffString }
        )
        if let oldSnapshots = try? context.fetch(descriptor) {
            for snap in oldSnapshots {
                context.delete(snap)
            }
            try? context.save()
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add Sources/UsageTracker.swift
git commit -m "refactor: rewrite UsageTracker to use async SwiftData queries"
```

---

## Task 4: 更新 StatusBarViewModel

**Files:**
- Modify: `Sources/StatusBarViewModel.swift`

- [ ] **Step 1: 修改 recordSnapshot 调用**

在 `StatusBarViewModel.swift` 的 `refresh()` 成功回调中，修改：

```swift
// 旧代码：
self.tracker.recordSnapshot(
    weeklyTotal: result.currentWeeklyTotalCount,
    weeklyRemain: result.currentWeeklyUsageCount
)

// 新代码：
self.tracker.recordSnapshot(model: result)
```

- [ ] **Step 2: 提交**

```bash
git add Sources/StatusBarViewModel.swift
git commit -m "feat: use new recordSnapshot(model:) API"
```

---

## Task 5: 更新 StatsView 使用 @Query 响应式绑定

**Files:**
- Modify: `Sources/App.swift`

**Context:** StatsView 需要改为使用 SwiftData @Query 直接绑定，避免手动管理异步

- [ ] **Step 1: 在 StatsView 添加 @Query**

查看 StatsView 当前实现，找到 `tracker` 属性使用处，替换为 @Query：

```swift
// 在 StatsView 结构体中添加
@Query private var allSnapshots: [IntervalSnapshot]
```

- [ ] **Step 2: 添加计算属性提供统计数据**

在 StatsView 中添加：

```swift
private var last7DaysData: [(date: Date, usage: Int)] {
    let calendar = Calendar.current
    var result: [(Date, Int)] = []
    
    for i in (0..<7).reversed() {
        let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
        let dateString = UsageTracker.dateString(from: date)
        
        // 过滤当天的快照，按 interval 分组取最大值
        let daySnapshots = allSnapshots.filter { $0.date == dateString }
        var maxByInterval: [Int: Int] = [:]
        for snap in daySnapshots {
            if let existing = maxByInterval[snap.intervalIndex] {
                maxByInterval[snap.intervalIndex] = max(existing, snap.usageCount)
            } else {
                maxByInterval[snap.intervalIndex] = snap.usageCount
            }
        }
        
        let dayTotal = (0..<5).reduce(0) { $0 + (maxByInterval[$1] ?? 0) }
        result.append((date, dayTotal))
    }
    
    return result
}

private var weeklyTotal: Int {
    last7DaysData.reduce(0) { $0 + $1.usage }
}

// 添加辅助方法（需要设为 static 或移到 UsageTracker）
fileprivate static func dateString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
}
```

- [ ] **Step 3: 替换 StatsView 中 tracker 调用**

将：
```swift
let tracker = UsageTracker.shared
let allData = tracker.last7DaysUsage(weeklyTotal: weeklyTotal)
let data = tracker.last7DaysUsage()
```

替换为使用 `last7DaysData` 计算属性

- [ ] **Step 4: 提交**

```bash
git add Sources/App.swift
git commit -m "feat: refactor StatsView to use @Query for reactive SwiftData binding"
```

---

## 验证步骤

1. **编译检查**: `xcodebuild -scheme MiniMaxMenuBar build`
2. **运行 App**: 打开 App，查看状态栏显示
3. **触发刷新**: 等待5分钟或手动触发 API 刷新
4. **检查存储**: 用 CoreDataViewer 或命令行验证 SwiftData 数据
5. **查看统计**: 打开统计视图，确认7天数据和周总量正确显示

---

## 注意事项

1. SwiftData 的 `@Query` 会在主线程自动更新视图，无需手动刷新
2. `UsageTracker` 的查询方法改为 async，需要用 `.task {}` 或 `Task {}` 调用
3. StatsView 的计算属性依赖 `@Query` 的自动更新，实现响应式
4. 窗口跨周时，每个窗口独立累计，不存在跨周问题

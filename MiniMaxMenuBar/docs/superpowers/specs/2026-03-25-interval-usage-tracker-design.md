# Interval Usage Tracker 设计文档

## 背景

MiniMax API 取消了 `currentWeeklyTotalCount` 和 `currentWeeklyUsageCount` 字段，无法直接获取周用量。需要改用窗口（interval）数据进行统计。

**窗口规则：**
- 每 5 小时一个窗口：0-5点、5-10点、10-15点、15-20点、20-24点
- 每天 5 个窗口
- API 返回 `currentIntervalTotalCount`（窗口总量）和 `currentIntervalUsageCount`（窗口已用量）

---

## 数据结构

### SwiftData Models

```swift
@Model
class IntervalSnapshot {
    @Attribute(.unique) var id: String          // date_intervalIndex_timestamp
    var date: String                            // 本地时间日期 "yyyy-MM-dd"
    var intervalIndex: Int                      // 窗口序号 0-4
    var totalCount: Int                         // currentIntervalTotalCount（窗口总量）
    var usageCount: Int                        // 窗口已用量 = 窗口内最后一条记录的 usageCount
    var timestamp: Date                         // 本地记录时间
    var startTime: Int64                        // API 原始 UTC interval 开始时间
    var endTime: Int64                          // API 原始 UTC interval 结束时间
}

@Model
class DailySnapshot {
    @Attribute(.unique) var date: String       // "yyyy-MM-dd"
    var dailyTotal: Int                         // 当日总用量（5个窗口之和）
    var weeklyTotal: Int                        // 本周总用量（7天之和）
    var timestamp: Date
}
```

---

## 核心逻辑

### 1. 记录快照（每次 API 刷新时调用）

```
给定 API 返回的 ModelRemain:
1. 根据 startTime 计算本地 date 和 intervalIndex
2. 生成唯一 id: "\(date)_\(intervalIndex)_\(timestamp.timeIntervalSince1970)"
3. 创建 IntervalSnapshot 并存入 SwiftData
4. 调用 cleanupOldData() 清理 30 天前的数据
```

### 2. 计算窗口用量

```
窗口用量 = 该窗口最后一条记录的 usageCount
```

### 3. 计算日用量

```
日用量 = sum(当天5个窗口的窗口用量)
       = sum(每个窗口最后一条记录的 usageCount)
```

### 4. 计算周用量

```
周用量 = sum(当天0点往前推7天的日用量)
```

---

## 算法细节

### date 和 intervalIndex 计算

```
输入: startTime (UTC 毫秒时间戳)
1. 转为本地 Date
2. 提取 dateString = "yyyy-MM-dd"
3. 根据 startTime 对应的本地小时:
   - 0-4点 -> intervalIndex = 0
   - 5-9点 -> intervalIndex = 1
   - 10-14点 -> intervalIndex = 2
   - 15-19点 -> intervalIndex = 3
   - 20-23点 -> intervalIndex = 4
```

---

## DailySnapshot 冗余优化

为提升查询效率，可在每日 23:59:59 或次日 00:00:00 计算并存储 `DailySnapshot`:

```
每日用量计算完成后:
1. 构建 DailySnapshot(dailyTotal: xxx, weeklyTotal: yyy)
2. 存入 SwiftData DailySnapshot
3. 查询天/周统计时直接读 DailySnapshot，避免重算
```

---

## 文件变更

| 文件 | 变更 |
|------|------|
| `Shared/QuotaModels.swift` | 新增 `IntervalSnapshot` 和 `DailySnapshot` SwiftData Model |
| `Sources/UsageTracker.swift` | 重写统计逻辑，支持按窗口存储和计算 |
| `Sources/StatusBarViewModel.swift` | 调用新 API 传入 interval 数据 |

---

## 兼容性

- 旧的 `DailySnapshot` 结构体（UserDefaults 用）可删除
- 旧的 `recordSnapshot(weeklyTotal:weeklyRemain:)` 接口需改为传入 interval 数据

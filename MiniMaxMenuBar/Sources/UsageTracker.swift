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
        
        // usageCount 是剩余量，窗口用量 = totalCount - usageCount
        let snapshot = IntervalSnapshot(
            date: dateString,
            intervalIndex: intervalIndex,
            totalCount: model.currentIntervalTotalCount,
            usageCount: model.currentIntervalTotalCount - model.currentIntervalUsageCount,
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
        let dateString = Self.dateStringFromDate(date)
        
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
    
    /// 根据 Date 计算本地日期字符串
    static func dateStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// 根据 UTC startTime 计算本地日期字符串
    static func dateString(from startTime: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(startTime) / 1000)
        return dateStringFromDate(date)
    }
    
    /// 根据 UTC startTime 计算窗口序号
    static func intervalIndex(from startTime: Int64) -> Int {
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
    @MainActor
    private func cleanupOldDataIfNeeded() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
        let cutoffString = Self.dateStringFromDate(cutoffDate)
        
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

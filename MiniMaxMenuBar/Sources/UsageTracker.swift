import Foundation

/// 使用量追踪服务
/// 记录每日配额快照，计算每日/每周使用量
class UsageTracker {
    static let shared = UsageTracker()

    private let storageKey = "USAGE_SNAPSHOTS"
    private let maxDays = 30

    /// 快照存储 [dateString: DailySnapshot]
    private var snapshots: [String: DailySnapshot] = [:]

    private init() {
        loadSnapshots()
    }

    // MARK: - Public Methods

    /// 记录当天配额快照（每次API刷新时调用）
    func recordSnapshot(weeklyTotal: Int, weeklyRemain: Int) {
        let dateString = Self.dateString(from: Date())
        let snapshot = DailySnapshot(
            date: dateString,
            weeklyTotal: weeklyTotal,
            weeklyRemain: weeklyRemain,
            timestamp: Date()
        )
        snapshots[dateString] = snapshot
        cleanupOldData()
        saveSnapshots()
    }

    /// 获取指定日期的使用量（基于周剩余计算）
    /// - Parameters:
    ///   - date: 目标日期
    ///   - weeklyTotal: 今日周总配额（用于跨周重置时计算）
    /// - Returns: 当天使用量
    func dailyUsage(for date: Date, weeklyTotal: Int = 0) -> Int {
        let dateString = Self.dateString(from: date)
        let todaySnapshot = snapshots[dateString]

        let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        let yesterdayString = Self.dateString(from: yesterdayDate)
        let yesterdaySnapshot = snapshots[yesterdayString]

        // 如果今天没有记录，返回0
        guard let todayWeeklyRemain = todaySnapshot?.weeklyRemain else {
            return 0
        }

        // 如果昨天没有快照，用周总-周剩余
        guard let yesterdayWeeklyRemain = yesterdaySnapshot?.weeklyRemain else {
            return max(0, weeklyTotal - todayWeeklyRemain)
        }

        // 检测跨周重置：如果今天周剩余 > 昨天周剩余，说明周重置了
        if todayWeeklyRemain > yesterdayWeeklyRemain {
            return max(0, weeklyTotal - todayWeeklyRemain)
        }

        let usage = yesterdayWeeklyRemain - todayWeeklyRemain
        return max(0, usage)
    }

    /// 获取近7天每日使用量
    /// - Parameter weeklyTotal: 今日周总配额（用于跨周重置时计算）
    /// - Returns: 按日期排序的 (日期, 使用量) 数组
    func last7DaysUsage(weeklyTotal: Int = 0) -> [(date: Date, usage: Int)] {
        var result: [(Date, Int)] = []
        let calendar = Calendar.current

        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let usage = dailyUsage(for: date, weeklyTotal: weeklyTotal)
            result.append((date, usage))
        }

        return result
    }

    /// 获取本周已使用量（API直接返回）
    func weeklyUsed(total: Int, remain: Int) -> Int {
        return total - remain
    }

    // MARK: - Private Methods

    private func loadSnapshots() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            snapshots = try JSONDecoder().decode([String: DailySnapshot].self, from: data)
        } catch {
            print("[UsageTracker] Load failed: \(error)")
            snapshots = [:]
        }
    }

    private func saveSnapshots() {
        do {
            let data = try JSONEncoder().encode(snapshots)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("[UsageTracker] Save failed: \(error)")
        }
    }

    /// 清理超过30天的旧数据
    private func cleanupOldData() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
        let cutoffString = Self.dateString(from: cutoffDate)

        snapshots = snapshots.filter { $0.key >= cutoffString }
    }

    /// 日期转字符串
    private static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

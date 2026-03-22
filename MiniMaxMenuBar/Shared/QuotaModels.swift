import Foundation

struct APIResponse: Codable {
    let modelRemains: [ModelRemain]
    let baseResp: BaseResp
}

struct BaseResp: Codable {
    let statusCode: Int
    let statusMsg: String
}

struct ModelRemain: Codable, Identifiable {
    let modelName: String
    /// 当前时间窗口总配额
    let currentIntervalTotalCount: Int
    /// 当前时间窗口剩余配额（可用次数）
    let currentIntervalUsageCount: Int
    let remainsTime: Int64
    let startTime: Int64
    let endTime: Int64
    /// 本周总配额
    let currentWeeklyTotalCount: Int
    /// 本周剩余配额（可用次数）
    let currentWeeklyUsageCount: Int
    let weeklyRemainsTime: Int64
    let weeklyStartTime: Int64
    let weeklyEndTime: Int64

    var id: String { modelName }

    var usagePercentage: Double {
        guard currentIntervalTotalCount > 0 else { return 0 }
        return Double(currentIntervalTotalCount - currentIntervalUsageCount) / Double(currentIntervalTotalCount)
    }

    var resetDate: Date {
        Date(timeIntervalSince1970: TimeInterval(endTime) / 1000)
    }

    var remainingTimeFormatted: String {
        let totalSeconds = Int(remainsTime / 1000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var resetDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: resetDate) + " UTC"
    }
}

/// 每日配额快照，用于使用量统计
struct DailySnapshot: Codable {
    /// 日期字符串 "2026-03-22"
    let date: String
    /// 当天记录的周总配额（用于跨周重置检测）
    let weeklyTotal: Int
    /// 当天记录的周剩余配额（用于计算日使用量）
    let weeklyRemain: Int
    /// 记录时间
    let timestamp: Date
}
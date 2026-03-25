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


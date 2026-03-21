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
    let currentIntervalTotalCount: Int
    let currentIntervalUsageCount: Int
    let remainsTime: Int64
    let startTime: Int64
    let endTime: Int64
    let currentWeeklyTotalCount: Int
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
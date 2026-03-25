import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var showSettings = false
    @State private var showStats = false
    @State private var apiKey: String = ConfigService.apiKey ?? ""
    @State private var groupId: String = ConfigService.groupId ?? ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if !ConfigService.isConfigured || showSettings {
                settingsForm
            } else if showStats {
                StatsView(viewModel: viewModel, showStats: $showStats)
            } else {
                mainContent
            }
        }
        .fixedSize()
    }

    private var mainContent: some View {
        VStack(spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                errorCard(message: errorMessage)
            } else if let quota = viewModel.quota {
                quotaCard(quota: quota)
            } else {
                loadingView
            }

            actionButtons
        }
        .padding(16)
    }

    private var settingsForm: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gear")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)

                Text("设置")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Key")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    SecureField("输入 API Key", text: $apiKey)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color(hex: "2d2d44"))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Group ID")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    TextField("输入 Group ID", text: $groupId)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color(hex: "2d2d44"))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }

            Button(action: saveSettings) {
                Text("保存")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cyan)
                    )
            }
            .buttonStyle(PlainButtonStyle())

            if ConfigService.isConfigured && !apiKey.isEmpty {
                Button(action: { showSettings = false }) {
                    Text("取消")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func saveSettings() {
        ConfigService.apiKey = apiKey
        ConfigService.groupId = groupId
        showSettings = false
        viewModel.refresh()
    }

    @ViewBuilder
    private func errorCard(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("出错了")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2d2d44").opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func quotaCard(quota: ModelRemain) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)

                Text(quota.modelName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    apiKey = ConfigService.apiKey ?? ""
                    groupId = ConfigService.groupId ?? ""
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(spacing: 8) {
                infoRow(icon: "play.circle", title: "窗口开始", value: formatTimestamp(quota.startTime), color: .green)
                infoRow(icon: "stop.circle", title: "窗口结束", value: formatTimestamp(quota.endTime), color: .red)
                infoRow(icon: "clock", title: "剩余时间", value: quota.remainingTimeFormatted, color: .orange)
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            HStack(spacing: 12) {
                statBox(title: "已用", value: "\(quota.currentIntervalTotalCount - quota.currentIntervalUsageCount)", total: "\(quota.currentIntervalTotalCount)", color: .blue)
                statBox(title: "剩余", value: "\(quota.currentIntervalUsageCount)", total: "\(quota.currentIntervalTotalCount)", color: .green)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2d2d44").opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.5), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func statBox(title: String, value: String, total: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)

                Text("/\(total)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.15))
        )
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))

            Text("加载中...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.refresh() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    Text("刷新")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cyan.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { showStats = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 12))
                    Text("统计")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { NSApp.terminate(nil) }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                    Text("退出")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func formatTimestamp(_ ms: Int64) -> String {
        let seconds = ms / 1000
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(identifier: "UTC")
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
    }
}

// MARK: - StatsView

struct StatsView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @Binding var showStats: Bool

    @Query private var allSnapshots: [IntervalSnapshot]

    private var last7DaysData: [(date: Date, usage: Int)] {
        let calendar = Calendar.current
        var result: [(Date, Int)] = []

        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dateString = UsageTracker.dateString(from: date)
            let daySnapshots = allSnapshots.filter { $0.date == dateString }

            var maxByInterval: [Int: Int] = [:]
            for snap in daySnapshots {
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
            result.append((date, total))
        }
        return result
    }

    private var weeklyTotal: Int {
        last7DaysData.reduce(0) { $0 + $1.usage }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)

                Text("使用统计")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showStats = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("返回")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.cyan)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Weekly summary
            if let quota = viewModel.quota {
                weeklySummaryCard(quota: quota)
            }

            // Divider with "近7日"
            dividerWithLabel()

            // 7 days chart
            chartSection

            // Bottom stats
            bottomStatsSection

            Spacer()
        }
        .padding(16)
        .frame(minWidth: 320)
    }

    @ViewBuilder
    private func weeklySummaryCard(quota: ModelRemain) -> some View {
        let weeklyUsed = quota.currentWeeklyTotalCount - quota.currentWeeklyUsageCount
        let percentage = progressPercentage(quota: quota) * 100

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("本周已用:")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(weeklyUsed) / \(quota.currentWeeklyTotalCount)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }

            // Text-based progress bar with █ and ░
            let barWidth = 18
            let filledCount = Int(CGFloat(barWidth) * progressPercentage(quota: quota))
            let emptyCount = barWidth - filledCount
            let progressBar = String(repeating: "█", count: filledCount) + String(repeating: "░", count: emptyCount)

            Text(progressBar)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "2d2d44").opacity(0.8))
        )
    }

    private func progressPercentage(quota: ModelRemain) -> CGFloat {
        let total = quota.currentWeeklyTotalCount
        let used = total - quota.currentWeeklyUsageCount
        guard total > 0 else { return 0 }
        return CGFloat(used) / CGFloat(total)
    }

    private func dividerWithLabel() -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            Text("近7日")
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }

    private var chartSection: some View {
        let data = Array(last7DaysData.reversed())  // newest first
        let maxUsage = data.map { $0.usage }.max() ?? 1

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(data.indices, id: \.self) { index in
                let item = data[index]
                chartRow(for: item.date, usage: item.usage, maxUsage: maxUsage)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func chartRow(for date: Date, usage: Int, maxUsage: Int) -> some View {
        HStack(spacing: 8) {
            // Date label
            Text(dayLabel(for: date))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 40, alignment: .leading)

            // Text-based progress bar with █ and ░
            Text(progressBarText(usage: usage, maxUsage: maxUsage, barWidth: 12))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.blue)

            Spacer()

            // Estimated value with ~ prefix
            Text("~\(usage)")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .trailing)
        }
    }

    private func progressBarText(usage: Int, maxUsage: Int, barWidth: Int) -> String {
        let filledCount: Int
        if maxUsage > 0 {
            filledCount = Int(CGFloat(barWidth) * CGFloat(usage) / CGFloat(maxUsage))
        } else {
            filledCount = 0
        }
        let emptyCount = barWidth - filledCount
        return String(repeating: "█", count: max(0, filledCount)) + String(repeating: "░", count: max(0, emptyCount))
    }

    private var bottomStatsSection: some View {
        let data = last7DaysData
        let total = weeklyTotal
        let avg = data.isEmpty ? 0 : total / data.count
        let maxVal = data.map { $0.usage }.max() ?? 0

        return HStack {
            Text("日均: ~\(avg)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Spacer()
            Text("最大: \(maxVal)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

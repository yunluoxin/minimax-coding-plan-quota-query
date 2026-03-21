import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: StatusBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if let quota = viewModel.quota {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quota.modelName)
                        .font(.headline)

                    HStack {
                        Text("当前窗口:")
                        Spacer()
                        Text(formatTimestamp(quota.startTime))
                    }
                    .font(.caption2)

                    HStack {
                        Text("窗口结束:")
                        Spacer()
                        Text(formatTimestamp(quota.endTime))
                    }
                    .font(.caption2)

                    HStack {
                        Text("窗口剩余:")
                        Spacer()
                        Text(quota.remainingTimeFormatted)
                            .foregroundColor(.orange)
                    }
                    .font(.caption2)

                    Divider()

                    HStack {
                        Text("已用:")
                        Text("\(quota.currentIntervalTotalCount - quota.currentIntervalUsageCount)/\(quota.currentIntervalTotalCount)")
                        Spacer()
                        Text("剩余: \(quota.currentIntervalUsageCount)")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }
            } else if viewModel.quota == nil && viewModel.errorMessage == nil {
                Text("加载中...")
                    .foregroundColor(.secondary)
            }

            Divider()

            Button("刷新") {
                viewModel.refresh()
            }
            .keyboardShortcut("r")

            Button("退出") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 250)
    }

    private func formatTimestamp(_ ms: Int64) -> String {
        let seconds = ms / 1000
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(identifier: "UTC")
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
    }
}
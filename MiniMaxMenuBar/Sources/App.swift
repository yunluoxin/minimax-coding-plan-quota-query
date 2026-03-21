import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: StatusBarViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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
        .fixedSize()
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

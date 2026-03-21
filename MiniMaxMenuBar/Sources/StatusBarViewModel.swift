import Foundation
import SwiftUI
import Combine

class StatusBarViewModel: ObservableObject {
    static let shared = StatusBarViewModel()

    @Published var quota: ModelRemain?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let service = QuotaService()
    private var timer: Timer?

    var statusBarText: String {
        if !ConfigService.isConfigured {
            return "N/A"
        }
        if let error = errorMessage, !error.isEmpty {
            return "!"
        }
        if let q = quota {
            let percentage = Int((1 - q.usagePercentage) * 100)
            return "\(percentage)%"
        }
        return "..."
    }

    var statusBarIcon: String {
        if !ConfigService.isConfigured {
            return "❓"
        }
        if errorMessage != nil {
            return "⚠️"
        }
        if let q = quota {
            let percentage = Int((1 - q.usagePercentage) * 100)
            if percentage > 70 {
                return "🟢"
            } else if percentage > 30 {
                return "🟡"
            } else {
                return "🔴"
            }
        }
        return "⚪"
    }

    init() {
        startAutoRefresh()
        refresh()
    }

    func refresh() {
        guard ConfigService.isConfigured else {
            DispatchQueue.main.async {
                self.errorMessage = "请设置 MINIMAX_API_KEY 环境变量"
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        Task {
            do {
                let result = try await service.fetchQuota()
                await MainActor.run {
                    self.quota = result
                    self.errorMessage = nil
                    self.isLoading = false
                }
            } catch let error as QuotaService.QuotaError {
                await MainActor.run {
                    switch error {
                    case .notConfigured:
                        self.errorMessage = "未配置 API Key"
                    case .requestFailed(let code, let msg):
                        self.errorMessage = "请求失败 (\(code)): \(msg)"
                    case .parseFailed:
                        self.errorMessage = "解析响应失败"
                    case .apiError(let code, let msg):
                        self.errorMessage = "API 错误 (\(code)): \(msg)"
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "未知错误: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
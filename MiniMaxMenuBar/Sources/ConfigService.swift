import Foundation

enum ConfigService {
    static let apiKey: String? = ProcessInfo.processInfo.environment["MINIMAX_API_KEY"]
    static let groupId: String? = ProcessInfo.processInfo.environment["MINIMAX_GROUP_ID"]
    static let endpoint: String = "https://api.minimaxi.com"

    static var isConfigured: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }
}
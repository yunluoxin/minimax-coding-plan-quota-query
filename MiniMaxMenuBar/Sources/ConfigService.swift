import Foundation

enum ConfigService {
    private static let apiKeyKey = "MINIMAX_API_KEY"
    private static let groupIdKey = "MINIMAX_GROUP_ID"

    static var apiKey: String? {
        get { UserDefaults.standard.string(forKey: apiKeyKey) }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyKey) }
    }

    static var groupId: String? {
        get { UserDefaults.standard.string(forKey: groupIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: groupIdKey) }
    }

    static let endpoint: String = "https://api.minimaxi.com"

    static var isConfigured: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        UserDefaults.standard.removeObject(forKey: groupIdKey)
    }
}

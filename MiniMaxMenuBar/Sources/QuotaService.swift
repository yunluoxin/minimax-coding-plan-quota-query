import Foundation

class QuotaService {
    private let endpoint = ConfigService.endpoint
    private let apiPath = "/v1/api/openplatform/coding_plan/remains"

    enum QuotaError: Error {
        case notConfigured
        case requestFailed(Int, String)
        case parseFailed
        case apiError(Int, String)
    }

    func fetchQuota() async throws -> ModelRemain {
        guard let apiKey = ConfigService.apiKey else {
            throw QuotaError.notConfigured
        }

        var urlString = endpoint + apiPath
        if let groupId = ConfigService.groupId, !groupId.isEmpty {
            urlString += "?GroupId=" + groupId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        }

        guard let url = URL(string: urlString) else {
            throw QuotaError.requestFailed(0, "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuotaError.requestFailed(0, "Invalid response")
        }

        if httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw QuotaError.requestFailed(httpResponse.statusCode, body)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let apiResponse: APIResponse
        do {
            apiResponse = try decoder.decode(APIResponse.self, from: data)
        } catch {
            let rawString = String(data: data, encoding: .utf8) ?? "nil"
            print("[QuotaService] Parse failed: \(error)")
            print("[QuotaService] Raw data: \(rawString)")
            throw QuotaError.parseFailed
        }

        if apiResponse.baseResp.statusCode != 0 {
            throw QuotaError.apiError(apiResponse.baseResp.statusCode, apiResponse.baseResp.statusMsg)
        }

        guard let firstModel = apiResponse.modelRemains.first else {
            throw QuotaError.parseFailed
        }

        return firstModel
    }
}
import Foundation

struct TranscriptionService: Sendable {
    enum ServiceError: LocalizedError {
        case missingAPIKey
        case invalidURL
        case invalidResponse
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "No API key configured. Add your OpenAI key in Settings."
            case .invalidURL:
                "Invalid or missing endpoint URL. Check your settings."
            case .invalidResponse:
                "Unexpected response from the server."
            case .serverError(let message):
                "Server error: \(message)"
            }
        }
    }

    struct Config: Sendable {
        let mode: TranscriptionMode
        let openAIKey: String
        let openAIModel: OpenAIModel
        let customURL: String
        let customAuthHeader: String
    }

    private struct TranscriptionResponse: Decodable {
        let text: String
    }

    func buildRequest(
        config: Config,
        audioData: Data
    ) throws -> URLRequest {
        let url: URL
        switch config.mode {
        case .openAI:
            guard !config.openAIKey.isEmpty else { throw ServiceError.missingAPIKey }
            url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        case .custom:
            guard !config.customURL.isEmpty, let parsed = URL(string: config.customURL) else {
                throw ServiceError.invalidURL
            }
            url = parsed
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        switch config.mode {
        case .openAI:
            request.setValue("Bearer \(config.openAIKey)", forHTTPHeaderField: "Authorization")
        case .custom:
            if !config.customAuthHeader.isEmpty {
                request.setValue(config.customAuthHeader, forHTTPHeaderField: "Authorization")
            }
        }

        var body = Data()
        let newline = "\r\n"

        // Audio file part
        body.append("--\(boundary)\(newline)")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\(newline)")
        body.append("Content-Type: audio/m4a\(newline)\(newline)")
        body.append(audioData)
        body.append(newline)

        // Model part (OpenAI only)
        if config.mode == .openAI {
            body.append("--\(boundary)\(newline)")
            body.append("Content-Disposition: form-data; name=\"model\"\(newline)\(newline)")
            body.append(config.openAIModel.rawValue)
            body.append(newline)
        }

        body.append("--\(boundary)--\(newline)")
        request.httpBody = body

        return request
    }

    func transcribe(request: URLRequest) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ServiceError.serverError(message)
        }
        return try parseResponse(data)
    }

    func parseResponse(_ data: Data) throws -> String {
        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return response.text
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

import Foundation

public enum TranscriptionStatus: String, Codable, Sendable {
    case idle
    case recording
    case stopping
    case uploading
    case done
    case error
}

public struct TranscriptionState: Codable, Sendable {
    public var status: TranscriptionStatus
    public var transcription: String?
    public var errorMessage: String?
    public var timestamp: Date?

    public init(
        status: TranscriptionStatus = .idle,
        transcription: String? = nil,
        errorMessage: String? = nil,
        timestamp: Date? = Date()
    ) {
        self.status = status
        self.transcription = transcription
        self.errorMessage = errorMessage
        self.timestamp = timestamp
    }

    public var isStale: Bool {
        guard let timestamp else { return true }
        return Date().timeIntervalSince(timestamp) > 30
    }

    public func save(to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: LamyConstants.SharedKey.state)
        }
    }

    public static func load(from defaults: UserDefaults) -> TranscriptionState {
        guard let data = defaults.data(forKey: LamyConstants.SharedKey.state),
              let state = try? JSONDecoder().decode(TranscriptionState.self, from: data)
        else {
            return TranscriptionState()
        }
        return state
    }
}

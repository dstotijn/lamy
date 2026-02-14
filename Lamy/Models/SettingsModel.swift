import Foundation
import Observation

enum TranscriptionMode: String, CaseIterable, Sendable {
    case openAI
    case custom
}

enum OpenAIModel: String, CaseIterable, Sendable {
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
    case whisper1 = "whisper-1"

    var displayName: String {
        switch self {
        case .gpt4oTranscribe: "GPT-4o Transcribe"
        case .gpt4oMiniTranscribe: "GPT-4o Mini Transcribe"
        case .whisper1: "Whisper v2"
        }
    }
}

@Observable @MainActor
final class SettingsModel {
    private enum Key {
        static let mode = "settings.mode"
        static let openAIModel = "settings.openAIModel"
        static let openAIKey = "settings.openAIKey"
        static let customURL = "settings.customURL"
        static let customAuthHeader = "settings.customAuthHeader"
    }

    private let defaults: UserDefaults
    private let keychain: KeychainHelper

    var mode: TranscriptionMode {
        didSet { defaults.set(mode.rawValue, forKey: Key.mode) }
    }

    var openAIModel: OpenAIModel {
        didSet { defaults.set(openAIModel.rawValue, forKey: Key.openAIModel) }
    }

    var openAIKey: String {
        didSet { try? keychain.save(key: Key.openAIKey, value: openAIKey) }
    }

    var customURL: String {
        didSet { defaults.set(customURL, forKey: Key.customURL) }
    }

    var customAuthHeader: String {
        didSet { try? keychain.save(key: Key.customAuthHeader, value: customAuthHeader) }
    }

    var transcriptionConfig: TranscriptionService.Config {
        .init(
            mode: mode,
            openAIKey: openAIKey,
            openAIModel: openAIModel,
            customURL: customURL,
            customAuthHeader: customAuthHeader
        )
    }

    var isConfigured: Bool {
        switch mode {
        case .openAI: !openAIKey.isEmpty
        case .custom: !customURL.isEmpty
        }
    }

    init(
        defaults: UserDefaults = .standard,
        keychain: KeychainHelper = KeychainHelper()
    ) {
        self.defaults = defaults
        self.keychain = keychain
        self.mode = TranscriptionMode(
            rawValue: defaults.string(forKey: Key.mode) ?? ""
        ) ?? .openAI
        self.openAIModel = OpenAIModel(
            rawValue: defaults.string(forKey: Key.openAIModel) ?? ""
        ) ?? .gpt4oTranscribe
        self.customURL = defaults.string(forKey: Key.customURL) ?? ""
        self.openAIKey = keychain.load(key: Key.openAIKey) ?? ""
        self.customAuthHeader = keychain.load(key: Key.customAuthHeader) ?? ""
    }
}

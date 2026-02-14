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
    private let defaults: UserDefaults
    private let keychain: KeychainHelper

    var mode: TranscriptionMode {
        didSet { defaults.set(mode.rawValue, forKey: "settings.mode") }
    }

    var openAIModel: OpenAIModel {
        didSet { defaults.set(openAIModel.rawValue, forKey: "settings.openAIModel") }
    }

    var openAIKey: String {
        get { keychain.load(key: "settings.openAIKey") ?? "" }
        set { try? keychain.save(key: "settings.openAIKey", value: newValue) }
    }

    var customURL: String {
        didSet { defaults.set(customURL, forKey: "settings.customURL") }
    }

    var customAuthHeader: String {
        get { keychain.load(key: "settings.customAuthHeader") ?? "" }
        set { try? keychain.save(key: "settings.customAuthHeader", value: newValue) }
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
            rawValue: defaults.string(forKey: "settings.mode") ?? ""
        ) ?? .openAI
        self.openAIModel = OpenAIModel(
            rawValue: defaults.string(forKey: "settings.openAIModel") ?? ""
        ) ?? .gpt4oTranscribe
        self.customURL = defaults.string(forKey: "settings.customURL") ?? ""
    }
}

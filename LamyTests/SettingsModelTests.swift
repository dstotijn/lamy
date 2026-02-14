import Foundation
import Testing
@testable import Lamy

@Suite("SettingsModel")
@MainActor
struct SettingsModelTests {
    @Test func defaultModeIsOpenAI() {
        let settings = SettingsModel(
            defaults: UserDefaults(suiteName: "test.settings")!,
            keychain: KeychainHelper()
        )
        #expect(settings.mode == .openAI)
    }

    @Test func openAIModelDefaultsToGPT4oTranscribe() {
        let settings = SettingsModel(
            defaults: UserDefaults(suiteName: "test.settings.model")!,
            keychain: KeychainHelper()
        )
        #expect(settings.openAIModel == .gpt4oTranscribe)
    }

    @Test func persistsModeToUserDefaults() {
        let suiteName = "test.settings.persist"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsModel(defaults: defaults, keychain: KeychainHelper())
        settings.mode = .custom
        #expect(defaults.string(forKey: "settings.mode") == "custom")
    }

    @Test func isConfiguredRequiresAPIKeyForOpenAI() {
        let suiteName = "test.settings.configured"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsModel(defaults: defaults, keychain: KeychainHelper())
        settings.mode = .openAI
        #expect(!settings.isConfigured)
    }

    @Test func isConfiguredRequiresURLForCustom() {
        let suiteName = "test.settings.customConfigured"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsModel(defaults: defaults, keychain: KeychainHelper())
        settings.mode = .custom
        #expect(!settings.isConfigured)

        settings.customURL = "https://example.com/transcribe"
        #expect(settings.isConfigured)
    }
}

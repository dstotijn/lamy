import Testing
import Foundation
@testable import Lamy
@testable import LamyShared

@Suite("TranscriptionManager", .serialized) @MainActor
struct TranscriptionManagerTests {
    private static let testKeychain = KeychainHelper(
        service: "com.dstotijn.lamy.tests"
    )

    private static func testSettings() -> SettingsModel {
        SettingsModel(keychain: testKeychain)
    }

    @Test func initialStateIsIdle() {
        let manager = TranscriptionManager(settings: Self.testSettings())
        #expect(manager.state.status == .idle)
    }

    @Test func handleStopWritesStoppingState() {
        let suiteName = "test.manager.stop"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let manager = TranscriptionManager(
            sharedDefaults: defaults,
            settings: Self.testSettings()
        )
        manager.state.status = .recording
        manager.handleStopSignal()

        let shared = TranscriptionState.load(from: defaults)
        #expect(shared.status == .stopping)
    }

    @Test func handleErrorWritesErrorState() {
        let suiteName = "test.manager.error"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let manager = TranscriptionManager(
            sharedDefaults: defaults,
            settings: Self.testSettings()
        )
        manager.writeError("Upload failed")

        #expect(manager.state.status == .error)
        let shared = TranscriptionState.load(from: defaults)
        #expect(shared.status == .error)
        #expect(shared.errorMessage == "Upload failed")
    }

    @Test func handleDoneWritesTranscription() {
        let suiteName = "test.manager.done"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let manager = TranscriptionManager(
            sharedDefaults: defaults,
            settings: Self.testSettings()
        )
        manager.writeDone(transcription: "Hello world")

        #expect(manager.state.status == .done)
        #expect(manager.state.transcription == "Hello world")
        let shared = TranscriptionState.load(from: defaults)
        #expect(shared.status == .done)
        #expect(shared.transcription == "Hello world")
    }
}

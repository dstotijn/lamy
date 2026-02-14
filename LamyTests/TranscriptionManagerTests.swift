import Testing
import Foundation
@testable import Lamy
@testable import LamyShared

@Suite("TranscriptionManager", .serialized) @MainActor
struct TranscriptionManagerTests {
    @Test func initialStateIsIdle() {
        let manager = TranscriptionManager(settings: SettingsModel())
        #expect(manager.state.status == .idle)
    }

    @Test func handleStopWritesStoppingState() {
        let suiteName = "test.manager.stop"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let manager = TranscriptionManager(sharedDefaults: defaults, settings: SettingsModel())
        manager.state.status = .recording
        manager.handleStopSignal()

        let shared = TranscriptionState.load(from: defaults)
        #expect(shared.status == .stopping)
    }

    @Test func handleErrorWritesErrorState() {
        let suiteName = "test.manager.error"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let manager = TranscriptionManager(sharedDefaults: defaults, settings: SettingsModel())
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

        let manager = TranscriptionManager(sharedDefaults: defaults, settings: SettingsModel())
        manager.writeDone(transcription: "Hello world")

        #expect(manager.state.status == .done)
        #expect(manager.state.transcription == "Hello world")
        let shared = TranscriptionState.load(from: defaults)
        #expect(shared.status == .done)
        #expect(shared.transcription == "Hello world")
    }
}

import Foundation
import Testing
@testable import LamyShared

@Suite("TranscriptionState")
struct TranscriptionStateTests {
    @Test func defaultStateIsIdle() {
        let state = TranscriptionState()
        #expect(state.status == .idle)
        #expect(state.transcription == nil)
        #expect(state.errorMessage == nil)
        #expect(state.timestamp != nil)
    }

    @Test func staleStateDetectedAfter30Seconds() {
        var state = TranscriptionState()
        state.status = .recording
        state.timestamp = Date().addingTimeInterval(-31)
        #expect(state.isStale)
    }

    @Test func recentStateNotStale() {
        var state = TranscriptionState()
        state.status = .recording
        state.timestamp = Date()
        #expect(!state.isStale)
    }

    @Test func roundTripsToUserDefaults() {
        let defaults = UserDefaults(suiteName: "test.transcriptionState")!
        defer { defaults.removePersistentDomain(forName: "test.transcriptionState") }

        var original = TranscriptionState()
        original.status = .done
        original.transcription = "Hello world"
        original.save(to: defaults)

        let loaded = TranscriptionState.load(from: defaults)
        #expect(loaded.status == .done)
        #expect(loaded.transcription == "Hello world")
    }
}

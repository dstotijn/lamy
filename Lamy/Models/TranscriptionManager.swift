import Foundation
import Observation
import LamyShared

@Observable @MainActor
final class TranscriptionManager {
    var state = TranscriptionState()

    private let sharedDefaults: UserDefaults
    private let audioRecorder = AudioRecorder()
    private let transcriptionService = TranscriptionService()
    private let settings: SettingsModel

    init(
        sharedDefaults: UserDefaults = LamyConstants.sharedDefaults,
        settings: SettingsModel
    ) {
        self.sharedDefaults = sharedDefaults
        self.settings = settings
    }

    func startRecording() {
        do {
            try audioRecorder.start()
            state.status = .recording
            state.timestamp = Date()
            syncToShared()
        } catch {
            writeError("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func handleStopSignal() {
        state.status = .stopping
        state.timestamp = Date()
        syncToShared()

        Task {
            guard let audioURL = audioRecorder.stop() else {
                writeError("No audio recorded")
                return
            }
            await uploadAndTranscribe(audioURL: audioURL)
        }
    }

    func syncFromShared() {
        let shared = TranscriptionState.load(from: sharedDefaults)
        if shared.status == .recording && state.status == .idle {
            startRecording()
        } else if shared.status == .stopping && state.status == .recording {
            handleStopSignal()
        }
    }

    func writeError(_ message: String) {
        state.status = .error
        state.errorMessage = message
        state.timestamp = Date()
        syncToShared()
        scheduleReset()
    }

    func writeDone(transcription: String) {
        state.status = .done
        state.transcription = transcription
        state.timestamp = Date()
        syncToShared()
        scheduleReset()
    }

    private func uploadAndTranscribe(audioURL: URL) async {
        state.status = .uploading
        state.timestamp = Date()
        syncToShared()

        do {
            let audioData = try Data(contentsOf: audioURL)
            let config = settings.transcriptionConfig
            let request = try transcriptionService.buildRequest(
                config: config,
                audioData: audioData
            )
            let text = try await transcriptionService.transcribe(request: request)
            writeDone(transcription: text)
            DarwinNotificationCenter.shared.post(LamyConstants.DarwinNotification.stateChanged)
        } catch {
            writeError("Transcription failed: \(error.localizedDescription)")
            DarwinNotificationCenter.shared.post(LamyConstants.DarwinNotification.stateChanged)
        }
    }

    private var resetTask: Task<Void, Never>?

    private func scheduleReset() {
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            state = TranscriptionState()
        }
    }

    private func syncToShared() {
        state.save(to: sharedDefaults)
    }
}

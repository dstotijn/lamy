import SwiftUI
import LamyShared

struct RecordingView: View {
    let manager: TranscriptionManager
    let settings: SettingsModel

    var body: some View {
        VStack(spacing: 24) {
            statusView
            actionButton
        }
        .padding()
    }

    @ViewBuilder
    private var statusView: some View {
        switch manager.state.status {
        case .idle:
            Label("Ready", systemImage: "mic")
                .foregroundStyle(.secondary)
        case .recording:
            Label("Recording…", systemImage: "mic.fill")
                .foregroundStyle(.red)
        case .stopping, .uploading:
            ProgressView("Transcribing…")
        case .done:
            Label("Done", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Label(
                manager.state.errorMessage ?? "Error",
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch manager.state.status {
        case .idle:
            VStack(spacing: 8) {
                Button("Start Recording") {
                    manager.startRecording()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!settings.isConfigured)

                if !settings.isConfigured {
                    Text("Add your API key in Settings to get started.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        case .recording:
            Button("Stop") {
                manager.handleStopSignal()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        default:
            EmptyView()
        }
    }
}

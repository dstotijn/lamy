import SwiftUI
import LamyShared

struct RecordingView: View {
    let manager: TranscriptionManager
    let settings: SettingsModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            statusText

            micButton

            unconfiguredHint
                .frame(height: 40, alignment: .top)

            Spacer()
            Spacer()
        }
        .padding()
    }

    static var placeholder: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Ready")
                .foregroundStyle(.secondary)
                .redacted(reason: .placeholder)

            Circle()
                .fill(.tint)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
                .redacted(reason: .placeholder)

            Spacer()
                .frame(height: 40)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Status Text

    @ViewBuilder
    private var statusText: some View {
        switch manager.state.status {
        case .idle:
            Text("Ready")
                .foregroundStyle(.secondary)
        case .recording:
            Text("Recording\u{2026}")
                .foregroundStyle(.red)
        case .stopping, .uploading:
            Text("Transcribing\u{2026}")
                .foregroundStyle(.secondary)
        case .done:
            Text("Done")
                .foregroundStyle(.green)
        case .error:
            Text(manager.state.errorMessage ?? "Error")
                .foregroundStyle(.red)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Mic Button

    @ViewBuilder
    private var micButton: some View {
        switch manager.state.status {
        case .idle:
            Button {
                manager.startRecording()
            } label: {
                micCircle(
                    icon: "mic.fill",
                    background: .tint,
                    opacity: settings.isConfigured ? 1 : 0.4
                )
            }
            .disabled(!settings.isConfigured)
            .accessibilityLabel(
                settings.isConfigured ? "Start recording" : "Start recording, disabled. Add API key in Settings."
            )

        case .recording:
            Button {
                manager.handleStopSignal()
            } label: {
                micCircle(icon: "stop.fill", background: .red)
            }
            .accessibilityLabel("Stop recording")
            .background { pulseRing }
            .onAppear { isPulsing = true }
            .onDisappear { isPulsing = false }

        case .stopping, .uploading:
            ProgressView()
                .controlSize(.large)
                .frame(width: 80, height: 80)

        case .done:
            micCircle(icon: "checkmark", background: .green)

        case .error:
            micCircle(
                icon: "exclamationmark.triangle.fill",
                background: Color.red.opacity(0.15),
                iconColor: .red
            )
        }
    }

    private func micCircle(
        icon: String,
        background: some ShapeStyle,
        opacity: Double = 1,
        iconColor: Color = .white
    ) -> some View {
        Circle()
            .fill(AnyShapeStyle(background))
            .frame(width: 80, height: 80)
            .opacity(opacity)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(iconColor)
            }
    }

    private var pulseRing: some View {
        Circle()
            .stroke(.red.opacity(0.4), lineWidth: 3)
            .frame(width: 80, height: 80)
            .scaleEffect(isPulsing && !reduceMotion ? 1.4 : 1)
            .opacity(isPulsing && !reduceMotion ? 0 : 0.4)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true),
                value: isPulsing
            )
    }

    // MARK: - Unconfigured Hint

    @ViewBuilder
    private var unconfiguredHint: some View {
        if manager.state.status == .idle && !settings.isConfigured {
            Text("Add your API key in Settings to get started.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

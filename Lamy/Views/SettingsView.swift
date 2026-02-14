import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
            modeSection
            switch settings.mode {
            case .openAI:
                openAISection
            case .custom:
                customSection
            }
        }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var modeSection: some View {
        Section("Transcription Provider") {
            Picker("Provider", selection: $settings.mode) {
                Text("OpenAI").tag(TranscriptionMode.openAI)
                Text("Custom").tag(TranscriptionMode.custom)
            }
        }
    }

    private var openAISection: some View {
        Section {
            SecureField("API Key", text: $settings.openAIKey)
                .textContentType(.password)
                .autocorrectionDisabled()

            Picker("Model", selection: $settings.openAIModel) {
                ForEach(OpenAIModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
        } header: {
            Text("OpenAI")
        } footer: {
            Text("Get your API key at platform.openai.com. Audio is sent to OpenAI for transcription.")
        }
    }

    private var customSection: some View {
        Section {
            TextField("URL", text: $settings.customURL)
                .textContentType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            SecureField("Authorization Header", text: $settings.customAuthHeader)
                .autocorrectionDisabled()
        } header: {
            Text("Custom Endpoint")
        } footer: {
            Text("Send audio to your own server. The authorization header is sent as-is in the Authorization field.")
        }
    }
}

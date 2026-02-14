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
        Section("Transcription Endpoint") {
            Picker("Mode", selection: $settings.mode) {
                Text("OpenAI").tag(TranscriptionMode.openAI)
                Text("Custom Endpoint").tag(TranscriptionMode.custom)
            }
            .pickerStyle(.segmented)
        }
    }

    private var openAISection: some View {
        Section("OpenAI Configuration") {
            SecureField("API Key", text: $settings.openAIKey)
                .textContentType(.password)
                .autocorrectionDisabled()

            Picker("Model", selection: $settings.openAIModel) {
                ForEach(OpenAIModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
        }
    }

    private var customSection: some View {
        Section("Custom Endpoint") {
            TextField("URL", text: $settings.customURL)
                .textContentType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            SecureField("Authorization Header", text: $settings.customAuthHeader)
                .autocorrectionDisabled()
        }
    }
}

import SwiftUI
import LamyShared

@main
struct LamyApp: App {
    @State private var settings = SettingsModel()
    @State private var manager: TranscriptionManager?
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if let manager {
                        RecordingView(manager: manager, settings: settings)
                    } else {
                        RecordingView.placeholder
                    }
                }
                .navigationTitle("Lamy")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
            .onOpenURL { url in
                guard url.scheme == LamyConstants.urlScheme else { return }
                if url.host == "record" {
                    manager?.startRecording()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    manager?.handleBackgrounding()
                }
            }
            .task {
                let mgr = TranscriptionManager(settings: settings)
                manager = mgr
                DarwinNotificationCenter.shared.observe(
                    LamyConstants.DarwinNotification.stateChanged
                ) {
                    Task { @MainActor in
                        mgr.syncFromShared()
                    }
                }
            }
        }
    }
}

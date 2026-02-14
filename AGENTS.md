# AGENTS.md

Project guidance for AI coding assistants working in this repository.

## Project Overview

Lamy is an iOS speech-to-text transcription app with a custom keyboard extension. The keyboard provides a mic button to trigger recording in the main app, which uploads audio to a transcription API (OpenAI or custom endpoint) and returns the text to the keyboard for insertion at the cursor.

## Architecture

Three Xcode targets in one project:

- **Lamy** (main app) — SwiftUI. Handles audio recording (AVAudioRecorder, M4A), server upload (URLSession async/await), transcription retrieval, and settings UI.
- **LamyKeyboard** (keyboard extension) — UIKit (`UIInputViewController`). Thin client: mic/stop button, status indicator, globe button. No networking, no audio. Inserts text via `textDocumentProxy.insertText()`.
- **LamyShared** (shared framework) — Constants for App Group IDs, shared UserDefaults keys, Darwin notification names.

## IPC Between App and Extension

- **App Groups**: Shared `UserDefaults` for state flags and transcription text. Shared file container for the M4A audio file.
- **Darwin notifications** (`CFNotificationCenter`): Cross-process signals (no payload). Used to notify each side of state changes without polling.
- **URL scheme** (`lamy://record`): Opens the main app from the keyboard extension when the app isn't already alive in background.

## Key Technical Decisions

- Keyboard extension is pure UIKit (not SwiftUI) — simpler for the minimal UI and avoids hosting overhead.
- Main app uses `@Observable` (not `ObservableObject`) — requires iOS 17+.
- Secrets (API keys, auth headers) stored in Keychain, not UserDefaults.
- Audio file written to App Group shared file container, not UserDefaults (size limits).
- Background audio mode keeps the main app alive while recording in background.
- Opening URLs from keyboard extension uses the responder chain workaround (no `UIApplication.shared.open()` in extensions).
- Keyboard extension also observes `UIApplication.didBecomeActiveNotification` to refresh state — Darwin notifications are dropped when the extension is suspended.
- Done/error states auto-reset to idle after 3 seconds in the main app UI (shared state is left for the keyboard to consume).

## Bundle IDs

- Main app: `com.dstotijn.lamy`
- Keyboard extension: `com.dstotijn.lamy.keyboard`

## Build & Run

```bash
# Build the project
xcodebuild -scheme Lamy -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -scheme Lamy -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test
xcodebuild -scheme Lamy -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:LamyTests/TestClassName/testMethodName test
```

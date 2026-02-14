# Lamy

An iOS keyboard for speech-to-text transcription. Tap the mic button in the keyboard, speak, and the transcribed text is inserted at your cursor.

## How It Works

1. Switch to the Lamy keyboard in any app
2. Tap the mic button — the main app opens and starts recording
3. Swipe back and tap stop — audio is uploaded for transcription
4. Transcribed text is automatically inserted at the cursor

Audio is sent as M4A to either the OpenAI transcription API or a custom endpoint you configure.

## Requirements

- iOS 17.0+
- Xcode 16+

## Setup

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`.

```bash
brew install xcodegen
xcodegen generate
open Lamy.xcodeproj
```

### Enable the Keyboard

After installing the app on your device or simulator:

1. Go to **Settings > General > Keyboard > Keyboards > Add New Keyboard**
2. Select **Lamy**
3. Tap **Lamy** and enable **Allow Full Access**

### Configure Transcription

Open the Lamy app and tap the gear icon:

- **OpenAI mode**: Enter your OpenAI API key. Supports GPT-4o Transcribe, GPT-4o Mini Transcribe, and Whisper.
- **Custom endpoint**: Enter a URL (and optional Authorization header) for any server that accepts multipart audio uploads and returns `{"text": "..."}`.

## Architecture

Three targets:

- **Lamy** — SwiftUI main app. Records audio, uploads to transcription API, manages state.
- **LamyKeyboard** — UIKit keyboard extension. Mic/stop button, status indicator. Inserts transcribed text via `textDocumentProxy`.
- **LamyShared** — Shared framework for constants, state types, and Darwin notification helpers.

IPC between the app and keyboard uses App Groups (shared UserDefaults + file container), Darwin notifications, and a URL scheme (`lamy://record`).

## Build

```bash
xcodebuild -scheme Lamy -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Test

```bash
xcodebuild -scheme Lamy -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## License

[MIT](LICENSE)

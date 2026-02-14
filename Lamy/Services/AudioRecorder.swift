import AVFoundation
import LamyShared

@MainActor
final class AudioRecorder {
    private var recorder: AVAudioRecorder?

    var isRecording: Bool { recorder?.isRecording ?? false }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(
            url: LamyConstants.audioFileURL,
            settings: settings
        )
        recorder?.record()
    }

    func stop() -> URL? {
        recorder?.stop()
        recorder = nil
        let url = LamyConstants.audioFileURL
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}

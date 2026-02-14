import Testing
import Foundation
@testable import Lamy

@Suite("TranscriptionService")
struct TranscriptionServiceTests {
    @Test func buildOpenAIRequest() throws {
        let service = TranscriptionService()
        let config = TranscriptionService.Config(
            mode: .openAI,
            openAIKey: "sk-test",
            openAIModel: .whisper1,
            customURL: "",
            customAuthHeader: ""
        )

        let request = try service.buildRequest(
            config: config,
            audioData: Data("fake audio".utf8)
        )

        #expect(request.url?.absoluteString == "https://api.openai.com/v1/audio/transcriptions")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        #expect(request.httpMethod == "POST")
        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        #expect(contentType.contains("multipart/form-data"))
    }

    @Test func buildCustomRequest() throws {
        let service = TranscriptionService()
        let config = TranscriptionService.Config(
            mode: .custom,
            openAIKey: "",
            openAIModel: .whisper1,
            customURL: "https://my-server.com/transcribe",
            customAuthHeader: "Bearer my-token"
        )

        let request = try service.buildRequest(
            config: config,
            audioData: Data("fake audio".utf8)
        )

        #expect(request.url?.absoluteString == "https://my-server.com/transcribe")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer my-token")
    }

    @Test func customRequestWithoutAuth() throws {
        let service = TranscriptionService()
        let config = TranscriptionService.Config(
            mode: .custom,
            openAIKey: "",
            openAIModel: .whisper1,
            customURL: "https://my-server.com/transcribe",
            customAuthHeader: ""
        )

        let request = try service.buildRequest(
            config: config,
            audioData: Data("fake audio".utf8)
        )

        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func parseTranscriptionResponse() throws {
        let service = TranscriptionService()
        let text = try service.parseResponse(Data(#"{"text": "Hello world"}"#.utf8))
        #expect(text == "Hello world")
    }

    @Test func invalidCustomURLThrows() {
        let service = TranscriptionService()
        let config = TranscriptionService.Config(
            mode: .custom,
            openAIKey: "",
            openAIModel: .whisper1,
            customURL: "",
            customAuthHeader: ""
        )

        #expect(throws: TranscriptionService.ServiceError.self) {
            try service.buildRequest(config: config, audioData: Data("fake".utf8))
        }
    }

    @Test func missingOpenAIKeyThrows() {
        let service = TranscriptionService()
        let config = TranscriptionService.Config(
            mode: .openAI,
            openAIKey: "",
            openAIModel: .whisper1,
            customURL: "",
            customAuthHeader: ""
        )

        #expect(throws: TranscriptionService.ServiceError.self) {
            try service.buildRequest(config: config, audioData: Data("fake".utf8))
        }
    }
}

import Foundation
import AVFoundation
import Speech

final class SpeechRecognitionService {
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var partialHandler: ((String) -> Void)?
    private(set) var latestTranscript: String = ""

    func startRecognition(onPartialResult: @escaping (String) -> Void) throws {
        stopImmediately()

        let locale = Locale.autoupdatingCurrent
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        self.recognizer = recognizer
        self.partialHandler = onPartialResult

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request
        self.latestTranscript = ""

        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let transcript = result.bestTranscription.formattedString
                self.latestTranscript = transcript
                self.partialHandler?(transcript)
            }

            if let error {
                AppLogger.speech.error("Speech recognition error: \(error.localizedDescription, privacy: .public)")
            }
        }

        AppLogger.speech.debug("Speech recognition started with on-device mode")
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }

    func stopRecognition() -> String {
        request?.endAudio()
        let finalText = latestTranscript
        stopImmediately()
        return finalText
    }

    func stopImmediately() {
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
        recognizer = nil
        partialHandler = nil
    }

    enum SpeechError: LocalizedError {
        case recognizerUnavailable

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                return "Speech recognizer is unavailable."
            }
        }
    }
}

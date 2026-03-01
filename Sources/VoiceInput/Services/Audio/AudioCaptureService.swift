import AVFoundation
import Foundation

final class AudioCaptureService {
    private let engine = AVAudioEngine()
    private var isCapturing = false

    func startCapture(onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) throws {
        guard !isCapturing else { return }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            onBuffer(buffer, time)
        }

        engine.prepare()
        try engine.start()
        isCapturing = true
        AppLogger.audio.debug("Audio capture started")
    }

    func stopCapture() {
        guard isCapturing else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
        AppLogger.audio.debug("Audio capture stopped")
    }
}

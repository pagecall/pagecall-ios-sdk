import AVFoundation

class VolumeRecorder {
    private let audioRecorder: AVAudioRecorder

    func destroy() {
        audioRecorder.stop()
    }

    init(_ _: AudioSessionManager) throws {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("nothing.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()

        audioRecorder.updateMeters()
    }

    static func normalize(power: Float, lowest: Float, highest: Float) -> Float {
        guard highest > lowest else { return 0 }

        let clampedPower = min(max(power, lowest), highest)

        let linear = (clampedPower - lowest) / (highest - lowest)
        let perceptual = pow(linear, 3) // 감각적으로 자연스럽게: 3~4 정도의 지수

        return perceptual
    }

    func averagePower() -> Float {
        audioRecorder.updateMeters()
        return audioRecorder.averagePower(forChannel: 0)
    }
}

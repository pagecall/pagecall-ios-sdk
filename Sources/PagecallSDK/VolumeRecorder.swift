import AVFoundation

class VolumeRecorder {
    private let audioRecorder: AVAudioRecorder
    var lowest: Float = -40 // -50 in MI
    var highest: Float = -10 // -10 in MI

    init() throws {
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

    private func normalizeSoundLevel(level: Float) -> Float {
        var level = max(0.0, level - lowest)
        level = min(level, highest - lowest)
        return level / (highest - lowest) // scaled to 0.0 ~ 1
    }

    func requestAudioVolume() -> Float {
        audioRecorder.updateMeters()
        let averagePower = audioRecorder.averagePower(forChannel: 0)
        let volume = normalizeSoundLevel(level: averagePower)
        return volume
    }

    func stop() {
        audioRecorder.stop()
    }

    deinit {
        stop()
    }
}

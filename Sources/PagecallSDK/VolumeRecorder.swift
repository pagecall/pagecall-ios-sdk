import AVFoundation

class VolumeRecorder {
    private let audioRecorder: AVAudioRecorder

    private let lowest: Float = -50
    private let highest: Float = -10

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

    var unusualAveragePowerCount = 0

    func requestAudioVolume() throws -> Float {
        audioRecorder.updateMeters()
        let averagePower = audioRecorder.averagePower(forChannel: 0)
        if averagePower == -120.0 {
            // 일부 기기에서 마이크 사용중 표시(주황색 동그라미)가 꺼지면서 볼륨이 계속 -120 으로 찍히는 경우가 있습니다.
            // 이 때는 AVAudioRecorder를 재생성해주면 해결됩니다.
            // 아무리 조용해도 -80 정도는 나오는 것이 정상입니다.
            unusualAveragePowerCount += 1
        }
        if unusualAveragePowerCount > 5 {
            unusualAveragePowerCount = 0
            throw PagecallError.audioRecorderBroken
        }
        if averagePower < -120 {
            throw PagecallError.audioRecorderPowerOutOfRange
        }
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

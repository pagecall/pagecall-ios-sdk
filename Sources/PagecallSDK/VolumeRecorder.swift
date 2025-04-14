import AVFoundation

class VolumeRecorder {
    private let audioRecorder: AVAudioRecorder

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

    static func normalize(power: Float, lowest: Float, highest: Float) -> Float {
        guard highest > lowest else { return 0 }

        let clampedPower = min(max(power, lowest), highest)

        let linear = (clampedPower - lowest) / (highest - lowest)
        let perceptual = pow(linear, 3) // 감각적으로 자연스럽게: 3~4 정도의 지수

        return perceptual
    }

    var unusualAveragePowerCount = 0

    func averagePower() throws -> Float {
        return try averagePower(strict: false)
    }

    func averagePower(strict: Bool) throws -> Float {
        audioRecorder.updateMeters()
        let averagePower = audioRecorder.averagePower(forChannel: 0)
        if averagePower == -120.0 {
            // 일부 기기에서 마이크 사용중 표시(주황색 동그라미)가 꺼지면서 볼륨이 계속 -120 으로 찍히는 경우가 있습니다.
            // 이 때는 AVAudioRecorder를 재생성해주면 해결됩니다.
            // 아무리 조용해도 -80 정도는 나오는 것이 정상입니다.
            if strict {
                throw PagecallError.audioRecorderBroken
            }
            unusualAveragePowerCount += 1
        }
        if unusualAveragePowerCount > 5 {
            unusualAveragePowerCount = 0
            throw PagecallError.audioRecorderBroken
        }
        return averagePower
    }

    func stop() {
        audioRecorder.stop()
    }

    deinit {
        stop()
    }
}

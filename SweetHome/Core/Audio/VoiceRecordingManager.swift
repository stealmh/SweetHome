//
//  VoiceRecordingManager.swift
//  SweetHome
//
//  Created by 김민호 on 9/27/25.
//

import Foundation
import AVFoundation

final class VoiceRecordingManager {

    // MARK: - Properties

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?

    private var currentState: VoiceRecordingState = .idle
    private var audioLevels: [AudioLevel] = []
    private var recordingStartTime: Date?
    private var recordingURL: URL?

    // MARK: - Audio Session Setup

    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
    }

    private func generateRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "voice_recording_\(Date().timeIntervalSince1970).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }

    // MARK: - Public Interface

    /// - 현재 녹음 상태 반환
    func getCurrentState() -> VoiceRecordingState {
        return currentState
    }

    /// - 현재까지 수집된 오디오 레벨들 반환
    func getAudioLevels() -> [AudioLevel] {
        return audioLevels
    }

    /// - 녹음 시작
    func startRecording() throws {
        guard currentState == .idle else {
            throw SHError.voiceRecordingError(.recordingFailed)
        }

        try setupAudioSession()

        let url = generateRecordingURL()
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true

        guard audioRecorder?.record() == true else {
            throw SHError.voiceRecordingError(.recordingFailed)
        }

        recordingStartTime = Date()
        audioLevels.removeAll()
        currentState = .recording(duration: 0)

        startRecordingTimer()
    }

    /// - 녹음 중지
    func stopRecording() throws {
        guard case .recording = currentState else {
            throw SHError.voiceRecordingError(.recordingFailed)
        }

        audioRecorder?.stop()
        stopRecordingTimer()

        if let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            currentState = .completed(duration: duration)
        }

        recordingStartTime = nil
    }

    /// - 재생 시작 또는 재개
    func startPlayback() throws {
        guard let url = recordingURL else {
            throw SHError.voiceRecordingError(.playbackFailed)
        }

        switch currentState {
        case .completed(let duration):
            // 처음 재생 시작
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            currentState = .playing(currentTime: 0, totalDuration: duration)

        case .paused(let currentTime, let totalDuration):
            // 일시정지에서 재개
            if audioPlayer == nil {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
            }
            audioPlayer?.currentTime = currentTime
            audioPlayer?.play()
            currentState = .playing(currentTime: currentTime, totalDuration: totalDuration)

        default:
            throw SHError.voiceRecordingError(.playbackFailed)
        }

        startPlaybackTimer()
    }

    /// - 재생 일시정지
    func pausePlayback() {
        guard case .playing(let currentTime, let totalDuration) = currentState else {
            return
        }

        audioPlayer?.pause()
        stopPlaybackTimer()
        currentState = .paused(currentTime: currentTime, totalDuration: totalDuration)
    }

    /// - 재생 완전 중지
    func stopPlayback() {
        audioPlayer?.stop()
        stopPlaybackTimer()

        if let duration = currentState.totalDuration {
            currentState = .completed(duration: duration)
        }
    }

    /// - 녹음 초기화 (재설정)
    func resetRecording() {
        audioRecorder?.stop()
        audioPlayer?.stop()
        stopRecordingTimer()
        stopPlaybackTimer()

        // 임시 파일 삭제
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        recordingURL = nil
        recordingStartTime = nil
        audioLevels.removeAll()
        audioPlayer = nil
        currentState = .idle
    }

    /// - 녹음된 오디오 데이터 반환
    func getRecordedAudioData() throws -> Data {
        guard let url = recordingURL else {
            throw SHError.voiceRecordingError(.fileNotFound)
        }

        return try Data(contentsOf: url)
    }

    // MARK: - Timer Management

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateRecordingProgress()
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: - Progress Updates

    private func updateRecordingProgress() {
        guard let recorder = audioRecorder,
              let startTime = recordingStartTime else { return }

        recorder.updateMeters()
        let currentTime = Date().timeIntervalSince(startTime)
        let averagePower = recorder.averagePower(forChannel: 0)

        // 데시벨을 0.0 ~ 1.0 범위로 변환 (-60dB ~ 0dB)
        let normalizedLevel = max(0.0, (averagePower + 60.0) / 60.0)

        let audioLevel = AudioLevel(timestamp: currentTime, level: normalizedLevel)
        audioLevels.append(audioLevel)

        currentState = .recording(duration: currentTime)
    }

    private func updatePlaybackProgress() {
        guard let player = audioPlayer,
              case .playing(_, let totalDuration) = currentState else {
            stopPlayback()
            return
        }

        if player.isPlaying {
            currentState = .playing(currentTime: player.currentTime, totalDuration: totalDuration)
        } else {
            // 재생 완료 - 처음으로 되돌림
            stopPlaybackTimer()
            currentState = .completed(duration: totalDuration)
        }
    }
}

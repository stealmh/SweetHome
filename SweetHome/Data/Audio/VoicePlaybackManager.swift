//
//  VoicePlaybackManager.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

/// - VoicePlaybackManager: 음성 메시지 재생을 전담하는 매니저
/// - 여러 음성 메시지 중 하나만 재생되도록 관리
final class VoicePlaybackManager: NSObject {

    // MARK: - Singleton

    static let shared = VoicePlaybackManager()
    private override init() {}

    // MARK: - Properties

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private let disposeBag = DisposeBag()

    /// - 현재 재생 중인 음성 메시지 데이터
    private var currentPlayingVoiceData: VoiceMessageData?

    /// - 재생 상태 스트림
    private let _playbackStateRelay = BehaviorRelay<[String: VoiceRecordingState]>(value: [:])
    var playbackStates: Observable<[String: VoiceRecordingState]> {
        return _playbackStateRelay.asObservable()
    }

    /// - 특정 음성 메시지의 재생 상태 스트림
    func playbackState(for voiceData: VoiceMessageData) -> Observable<VoiceRecordingState> {
        return _playbackStateRelay
            .map { states in
                return states[voiceData.generatedFileName] ?? .completed(duration: voiceData.duration)
            }
            .distinctUntilChanged()
    }

    // MARK: - Public Methods

    /// - 음성 메시지 재생/일시정지 토글 (다운로드 후 재생)
    func togglePlayback(for voiceData: VoiceMessageData, relativePath: String? = nil) {
        let fileName = voiceData.generatedFileName
        let currentState = _playbackStateRelay.value[fileName] ?? .completed(duration: voiceData.duration)

        switch currentState {
        case .completed, .idle:
            /// - 다운로드된 데이터가 있으면 재생, 없으면 에러
            if !voiceData.audioData.isEmpty {
                startPlaybackWithData(for: voiceData)
            } else {
                print("❌ VoicePlaybackManager: No audio data available for \(fileName)")
                simulatePlayback(for: voiceData)
            }

        case .playing:
            pausePlayback(for: voiceData)

        case .paused:
            resumePlayback(for: voiceData)

        case .recording:
            break /// - 녹음 중에는 재생할 수 없음
        }
    }

    /// - 모든 재생 중지
    func stopAllPlayback() {
        player?.pause()
        removeTimeObserver()
        currentPlayingVoiceData = nil

        /// - 모든 상태를 completed로 변경
        var newStates = _playbackStateRelay.value
        for (fileName, state) in newStates {
            if let duration = state.totalDuration {
                newStates[fileName] = .completed(duration: duration)
            }
        }
        _playbackStateRelay.accept(newStates)
    }

    /// - 특정 음성 메시지 재생 중지
    func stopPlayback(for voiceData: VoiceMessageData) {
        let fileName = voiceData.generatedFileName

        if currentPlayingVoiceData?.generatedFileName == fileName {
            player?.pause()
            removeTimeObserver()
            currentPlayingVoiceData = nil
        }

        var newStates = _playbackStateRelay.value
        newStates[fileName] = .completed(duration: voiceData.duration)
        _playbackStateRelay.accept(newStates)
    }

    // MARK: - Private Methods


    /// - 캐시된 데이터로 재생
    private func startPlaybackWithData(for voiceData: VoiceMessageData) {
        /// - 다른 음성이 재생 중이라면 중지
        if let currentData = currentPlayingVoiceData, currentData.generatedFileName != voiceData.generatedFileName {
            stopPlayback(for: currentData)
        }

        /// - 오디오 세션 설정
        do {
            try setupAudioSessionForPlayback()
        } catch {
            print("❌ VoicePlaybackManager: Failed to setup audio session - \(error)")
        }

        do {
            /// - 임시 파일 생성
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileName = "\(voiceData.generatedFileName)"
            let tempFileURL = tempDirectory.appendingPathComponent(tempFileName)

            /// - 데이터를 임시 파일에 저장
            try voiceData.audioData.write(to: tempFileURL)

            print("📁 VoicePlaybackManager: Created temp file: \(tempFileURL), size: \(voiceData.audioData.count) bytes")

            /// - AVPlayerItem 생성
            playerItem = AVPlayerItem(url: tempFileURL)
            player = AVPlayer(playerItem: playerItem)

            /// - 재생 상태 관찰
            setupPlayerObservers(for: voiceData)

            /// - 재생 시작
            player?.play()
            currentPlayingVoiceData = voiceData
            updateState(for: voiceData, state: .playing(currentTime: 0, totalDuration: voiceData.duration))

            /// - 재생 완료 후 임시 파일 삭제
            DispatchQueue.main.asyncAfter(deadline: .now() + voiceData.duration + 2.0) {
                try? FileManager.default.removeItem(at: tempFileURL)
            }

            print("✅ VoicePlaybackManager: Started playback with cached data")

        } catch {
            print("❌ VoicePlaybackManager: Failed to play with data - \(error)")
            simulatePlayback(for: voiceData)
        }
    }


    private func pausePlayback(for voiceData: VoiceMessageData) {
        let fileName = voiceData.generatedFileName
        guard currentPlayingVoiceData?.generatedFileName == fileName else { return }

        let currentTime = player?.currentTime().seconds ?? 0
        player?.pause()
        removeTimeObserver()

        updateState(for: voiceData, state: .paused(currentTime: currentTime, totalDuration: voiceData.duration))
    }

    private func resumePlayback(for voiceData: VoiceMessageData) {
        let fileName = voiceData.generatedFileName
        let currentState = _playbackStateRelay.value[fileName] ?? .completed(duration: voiceData.duration)

        guard case .paused(let currentTime, let totalDuration) = currentState else { return }

        if currentPlayingVoiceData?.generatedFileName != fileName {
            /// - 다른 파일이 현재 재생 중이라면 새로 시작
            if !voiceData.audioData.isEmpty {
                startPlaybackWithData(for: voiceData)
            } else {
                simulatePlayback(for: voiceData)
            }
            return
        }

        let seekTime = CMTime(seconds: currentTime, preferredTimescale: 1000)
        player?.seek(to: seekTime)
        player?.play()
        setupTimeObserver(for: voiceData)
        updateState(for: voiceData, state: .playing(currentTime: currentTime, totalDuration: totalDuration))
    }

    /// - AVPlayer 관찰자 설정
    private func setupPlayerObservers(for voiceData: VoiceMessageData) {
        setupTimeObserver(for: voiceData)
        setupPlayerItemObservers()
    }

    /// - 시간 관찰자 설정
    private func setupTimeObserver(for voiceData: VoiceMessageData) {
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdate(time, for: voiceData)
        }
    }

    /// - PlayerItem 관찰자 설정
    private func setupPlayerItemObservers() {
        guard let playerItem = playerItem else { return }

        /// - 재생 완료 알림
        NotificationCenter.default.rx
            .notification(.AVPlayerItemDidPlayToEndTime, object: playerItem)
            .subscribe(onNext: { [weak self] _ in
                self?.handlePlaybackDidFinish()
            })
            .disposed(by: disposeBag)

        /// - 재생 상태 관찰 (RxSwift 방식)
        playerItem.rx.observeWeakly(AVPlayerItem.Status.self, "status")
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] status in
                self?.handlePlayerItemStatusChange(status)
            })
            .disposed(by: disposeBag)
    }

    /// - 시간 업데이트 처리
    private func handleTimeUpdate(_ time: CMTime, for voiceData: VoiceMessageData) {
        let currentTime = time.seconds
        updateState(for: voiceData, state: .playing(currentTime: currentTime, totalDuration: voiceData.duration))

        /// - 재생 완료 확인 (duration과 거의 같아지면 완료 처리)
        if currentTime >= voiceData.duration - 0.1 {
            handlePlaybackDidFinish()
        }
    }

    /// - 재생 완료 처리
    private func handlePlaybackDidFinish() {
        guard let voiceData = currentPlayingVoiceData else { return }
        removeTimeObserver()
        updateState(for: voiceData, state: .completed(duration: voiceData.duration))
        currentPlayingVoiceData = nil
    }

    /// - 시간 관찰자 제거
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    /// - PlayerItem 상태 변화 처리
    private func handlePlayerItemStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .failed:
            if let error = playerItem?.error {
                print("❌ VoicePlaybackManager: Player item failed - \(error.localizedDescription)")
                print("❌ VoicePlaybackManager: Error code: \((error as NSError).code), domain: \((error as NSError).domain)")

                /// - 더 자세한 에러 정보 출력
                if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("❌ VoicePlaybackManager: Underlying error: \(underlyingError.localizedDescription)")
                }
            }
            if let voiceData = currentPlayingVoiceData {
                /// - 스트리밍 실패 시 캐시된 데이터로 재시도
                if !voiceData.audioData.isEmpty {
                    print("🔄 VoicePlaybackManager: Retrying with cached data")
                    startPlaybackWithData(for: voiceData)
                } else {
                    print("🔄 VoicePlaybackManager: No cached data available, using simulation")
                    simulatePlayback(for: voiceData)
                }
            }
        case .readyToPlay:
            print("✅ VoicePlaybackManager: Player item ready to play")
        case .unknown:
            print("🔄 VoicePlaybackManager: Player item status unknown")
        @unknown default:
            print("⚠️ VoicePlaybackManager: Unknown player item status")
        }
    }

    /// - 실제 오디오 파일이 없을 때의 더미 재생 시뮬레이션
    private func simulatePlayback(for voiceData: VoiceMessageData) {
        currentPlayingVoiceData = voiceData
        updateState(for: voiceData, state: .playing(currentTime: 0, totalDuration: voiceData.duration))

        /// - 더미 재생 타이머 (5초 후 완료로 처리)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.currentPlayingVoiceData?.generatedFileName == voiceData.generatedFileName {
                self?.updateState(for: voiceData, state: .completed(duration: voiceData.duration))
                self?.currentPlayingVoiceData = nil
            }
        }
    }

    private func updateState(for voiceData: VoiceMessageData, state: VoiceRecordingState) {
        var newStates = _playbackStateRelay.value
        newStates[voiceData.generatedFileName] = state
        _playbackStateRelay.accept(newStates)
    }

    // MARK: - Cleanup

    deinit {
        removeTimeObserver()
        player?.pause()
        player = nil
        playerItem = nil
    }

    // MARK: - Audio Session Setup

    private func setupAudioSessionForPlayback() throws {
        let audioSession = AVAudioSession.sharedInstance()

        /// - 재생과 녹음이 모두 가능하도록 설정 (채팅 앱 특성상)
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)

        print("✅ VoicePlaybackManager: Audio session configured for playback")
    }
}

// MARK: - Extensions

extension VoicePlaybackManager {
    /// - 특정 음성 메시지가 현재 재생 중인지 확인
    func isPlaying(_ voiceData: VoiceMessageData) -> Bool {
        let fileName = voiceData.generatedFileName
        let state = _playbackStateRelay.value[fileName] ?? .completed(duration: voiceData.duration)
        return state.isPlaying
    }

    /// - 특정 음성 메시지가 일시정지 상태인지 확인
    func isPaused(_ voiceData: VoiceMessageData) -> Bool {
        let fileName = voiceData.generatedFileName
        let state = _playbackStateRelay.value[fileName] ?? .completed(duration: voiceData.duration)
        return state.isPaused
    }
}
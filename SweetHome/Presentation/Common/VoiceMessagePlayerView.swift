//
//  VoiceMessagePlayerView.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// - VoiceMessagePlayerView: 음성 메시지 재생을 위한 공통 UI 컴포넌트
/// - 재생/일시정지 버튼, 웨이브폼, 재생시간을 포함
final class VoiceMessagePlayerView: UIView {

    // MARK: - UI Components

    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 20
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        return button
    }()

    private let waveformView = AudioWaveformView()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "0:00"
        return label
    }()

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.text = "0:00"
        return label
    }()

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var voiceMessageData: VoiceMessageData?
    private var audioLevels: [AudioLevel] = []

    /// - 재생/일시정지 버튼 탭 이벤트
    var playPauseButtonTapped: Observable<Void> {
        return playPauseButton.rx.tap.asObservable()
    }

    /// - 현재 재생 상태
    private let _playbackState = BehaviorRelay<VoiceRecordingState>(value: .idle)
    var playbackState: Observable<VoiceRecordingState> {
        return _playbackState.asObservable()
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bindActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        bindActions()
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubviews(playPauseButton, waveformView, currentTimeLabel, durationLabel)

        playPauseButton.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }

        currentTimeLabel.snp.makeConstraints {
            $0.leading.equalTo(playPauseButton.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        waveformView.snp.makeConstraints {
            $0.leading.equalTo(currentTimeLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(40)
        }

        durationLabel.snp.makeConstraints {
            $0.leading.equalTo(waveformView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(35)
        }
    }

    private func bindActions() {
        /// - 재생 상태에 따른 UI 업데이트
        _playbackState
            .subscribe(onNext: { [weak self] state in
                self?.updateUI(for: state)
            })
            .disposed(by: disposeBag)

    }

    // MARK: - Public Methods

    /// - 음성 메시지 데이터로 설정
    func configure(with data: VoiceMessageData, audioLevels: [AudioLevel] = []) {
        self.voiceMessageData = data
        self.audioLevels = audioLevels

        /// - 웨이브폼 설정
        if !audioLevels.isEmpty {
            waveformView.updateWithCompletedLevels(audioLevels)
        } else {
            /// - 오디오 레벨이 없는 경우 기본 웨이브폼 생성
            let defaultLevels = generateDefaultAudioLevels(for: data.duration)
            waveformView.updateWithCompletedLevels(defaultLevels)
        }

        /// - 재생 시간 설정
        durationLabel.text = formatTime(data.duration)
        currentTimeLabel.text = "0:00"

        /// - 초기 상태 설정
        _playbackState.accept(.completed(duration: data.duration))
    }

    /// - 재생 상태 업데이트
    func updatePlaybackState(_ state: VoiceRecordingState) {
        _playbackState.accept(state)
    }

    /// - 재생 진행률 업데이트
    func updateProgress(_ progress: Float, currentTime: TimeInterval) {
        waveformView.updatePlaybackProgress(progress)
        currentTimeLabel.text = formatTime(currentTime)
    }

    // MARK: - Private Methods

    private func updateUI(for state: VoiceRecordingState) {
        switch state {
        case .idle, .completed:
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            waveformView.updatePlaybackProgress(0)
            if let duration = state.totalDuration {
                currentTimeLabel.text = "0:00"
                durationLabel.text = formatTime(duration)
            }

        case .playing(let currentTime, let totalDuration):
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            let progress = Float(currentTime / totalDuration)
            waveformView.updatePlaybackProgress(progress)
            currentTimeLabel.text = formatTime(currentTime)
            durationLabel.text = formatTime(totalDuration)

        case .paused(let currentTime, let totalDuration):
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            let progress = Float(currentTime / totalDuration)
            waveformView.updatePlaybackProgress(progress)
            currentTimeLabel.text = formatTime(currentTime)
            durationLabel.text = formatTime(totalDuration)

        case .recording(let duration):
            /// - 녹음 중은 이 컴포넌트에서 사용되지 않음
            break
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func generateDefaultAudioLevels(for duration: TimeInterval) -> [AudioLevel] {
        /// - 기본 웨이브폼 패턴 생성 (60개 막대 기준)
        let numberOfBars = 60
        let timeStep = duration / Double(numberOfBars)
        var levels: [AudioLevel] = []

        for i in 0..<numberOfBars {
            let timestamp = Double(i) * timeStep
            /// - 랜덤한 높이로 자연스러운 웨이브 생성
            let level = Float.random(in: 0.2...0.8)
            levels.append(AudioLevel(timestamp: timestamp, level: level))
        }

        return levels
    }
}

// MARK: - Layout Configuration

extension VoiceMessagePlayerView {
    /// - 컴팩트 모드 (작은 셀에서 사용)
    func setCompactMode(_ isCompact: Bool) {
        if isCompact {
            playPauseButton.snp.updateConstraints {
                $0.size.equalTo(32)
            }

            waveformView.snp.updateConstraints {
                $0.height.equalTo(32)
            }

            currentTimeLabel.font = .systemFont(ofSize: 11, weight: .medium)
            durationLabel.font = .systemFont(ofSize: 11, weight: .medium)
        } else {
            playPauseButton.snp.updateConstraints {
                $0.size.equalTo(40)
            }

            waveformView.snp.updateConstraints {
                $0.height.equalTo(40)
            }

            currentTimeLabel.font = .systemFont(ofSize: 12, weight: .medium)
            durationLabel.font = .systemFont(ofSize: 12, weight: .medium)
        }
    }

    /// - 색상 테마 설정 (내 메시지용 흰색 테마)
    func setWhiteTheme() {
        playPauseButton.tintColor = .white
        currentTimeLabel.textColor = .white
        durationLabel.textColor = .white
        waveformView.setWhiteTheme()
    }

    /// - 색상 테마 설정 (상대방 메시지용 기본 테마)
    func setDefaultTheme() {
        playPauseButton.tintColor = .systemBlue
        currentTimeLabel.textColor = .label
        durationLabel.textColor = .secondaryLabel
        waveformView.setDefaultTheme()
    }
}
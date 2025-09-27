//
//  VoiceRecordingBottomSheet.swift
//  SweetHome
//
//  Created by 김민호 on 9/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// - VoiceRecordingBottomSheet: 음성 녹음을 위한 바텀시트 UI
/// - 녹음, 재생, 전송 기능을 제공하는 바텀시트
final class VoiceRecordingBottomSheet: UIViewController {

    // MARK: - UI Components

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray4
        v.layer.cornerRadius = 2
        return v
    }()

    private let titleLabel: UILabel = {
        let v = UILabel()
        v.text = "음성메세지"
        v.font = .systemFont(ofSize: 18, weight: .semibold)
        v.textAlignment = .center
        return v
    }()

    private let timeLabel: UILabel = {
        let v = UILabel()
        v.text = "00:00"
        v.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        v.textColor = .systemBlue
        v.textAlignment = .center
        return v
    }()

    private let waveformContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 8
        return v
    }()

    private let playButton: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(systemName: "play.fill"), for: .normal)
        v.tintColor = .systemBlue
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 4
        v.layer.shadowOpacity = 0.1
        v.isHidden = true  /// - 초기에는 숨김
        return v
    }()

    private let waveformView = AudioWaveformView()

    private let cancelButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("취소", for: .normal)
        v.setTitleColor(.systemRed, for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 24
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.systemRed.cgColor
        return v
    }()

    private let recordButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("녹음", for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        v.backgroundColor = .systemRed
        v.layer.cornerRadius = 24
        return v
    }()

    private let sendButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("전송", for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 24
        v.isEnabled = false
        v.alpha = 0.5
        return v
    }()

    // MARK: - Properties

    private let voiceRecordingManager = VoiceRecordingManager()
    private let permissionManager = AudioPermissionManager.shared
    private let disposeBag = DisposeBag()

    private var currentState: VoiceRecordingState = .idle {
        didSet {
            updateUI(for: currentState)
        }
    }

    private var stateUpdateTimer: Timer?

    // MARK: - Closures

    var onVoiceDataReady: ((Data) -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bind()
        startStateMonitoring()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stateUpdateTimer?.invalidate()
        voiceRecordingManager.resetRecording()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        view.addSubview(containerView)
        containerView.addSubviews(
            handleView,
            titleLabel,
            timeLabel,
            waveformContainerView,
            cancelButton,
            recordButton,
            sendButton
        )

        waveformContainerView.addSubviews(playButton, waveformView)

        /// - 바텀시트 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        containerView.addGestureRecognizer(panGesture)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(280)
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(36)
            $0.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }

        waveformContainerView.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(60)
        }

        playButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40)
        }

        waveformView.snp.makeConstraints {
            $0.leading.equalTo(playButton.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-8)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(44)
        }

        let buttonHeight: CGFloat = 48
        let buttonSpacing: CGFloat = 12

        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(buttonHeight)
            $0.width.equalTo(80)
        }

        sendButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(buttonHeight)
            $0.width.equalTo(80)
        }

        recordButton.snp.makeConstraints {
            $0.leading.equalTo(cancelButton.snp.trailing).offset(buttonSpacing)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-buttonSpacing)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(buttonHeight)
        }
    }

    private func bind() {
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleCancelTapped()
            })
            .disposed(by: disposeBag)

        recordButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleRecordTapped()
            })
            .disposed(by: disposeBag)

        sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleSendTapped()
            })
            .disposed(by: disposeBag)

        playButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handlePlayTapped()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - State Management

    private func startStateMonitoring() {
        stateUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateState()
        }
    }

    private func updateState() {
        let newState = voiceRecordingManager.getCurrentState()
        if newState != currentState {
            currentState = newState
        }
        updateAudioLevels()
    }

    private func updateAudioLevels() {
        let levels = voiceRecordingManager.getAudioLevels()

        switch currentState {
        case .recording:
            if let lastLevel = levels.last {
                waveformView.updateWithRealTimeLevel(lastLevel.level)
            }
        case .completed:
            waveformView.updateWithCompletedLevels(levels)
        default:
            break
        }
    }

    // MARK: - Action Handlers

    private func handleRecordTapped() {
        Task {
            do {
                switch currentState {
                case .idle:
                    let hasPermission = try await permissionManager.checkAndRequestPermission()
                    if hasPermission {
                        try voiceRecordingManager.startRecording()
                    }
                case .recording:
                    try voiceRecordingManager.stopRecording()
                case .completed:
                    voiceRecordingManager.resetRecording()
                default:
                    break
                }
            } catch {
                if case SHError.voiceRecordingError(.permissionDenied) = SHError.from(error) {
                    await MainActor.run {
                        showPermissionDeniedAlert()
                    }
                } else {
                    await MainActor.run {
                        showErrorAlert(message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func handlePlayTapped() {
        do {
            switch currentState {
            case .completed:
                try voiceRecordingManager.startPlayback()
            case .playing:
                voiceRecordingManager.pausePlayback()
            case .paused:
                try voiceRecordingManager.startPlayback()
            default:
                break
            }
        } catch {
            showErrorAlert(message: error.localizedDescription)
        }
    }

    private func handleSendTapped() {
        do {
            let audioData = try voiceRecordingManager.getRecordedAudioData()
            onVoiceDataReady?(audioData)
            dismiss(animated: true) {
                self.onDismiss?()
            }
        } catch {
            showErrorAlert(message: error.localizedDescription)
        }
    }

    private func handleCancelTapped() {
        voiceRecordingManager.resetRecording()
        dismiss(animated: true) {
            self.onDismiss?()
        }
    }

    // MARK: - UI Updates

    private func updateUI(for state: VoiceRecordingState) {
        switch state {
        case .idle:
            timeLabel.text = "00:00"
            recordButton.setTitle("녹음", for: .normal)
            recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            recordButton.backgroundColor = .systemRed
            recordButton.tintColor = .white
            playButton.isHidden = true
            sendButton.isEnabled = false
            sendButton.alpha = 0.5

        case .recording(let duration):
            timeLabel.text = formatTime(duration)
            recordButton.setTitle("중지", for: .normal)
            recordButton.setImage(UIImage(systemName: "rectangle"), for: .normal)
            recordButton.backgroundColor = .systemGray
            recordButton.tintColor = .white
            playButton.isHidden = true
            sendButton.isEnabled = false
            sendButton.alpha = 0.5

        case .completed(let duration):
            timeLabel.text = formatTime(duration)
            recordButton.setTitle("다시 녹음", for: .normal)
            recordButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
            recordButton.backgroundColor = .systemGray
            recordButton.tintColor = .black
            playButton.isHidden = false
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            sendButton.isEnabled = true
            sendButton.alpha = 1.0

        case .playing(let currentTime, let totalDuration):
            timeLabel.text = "\(formatTime(currentTime)) / \(formatTime(totalDuration))"
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)

        case .paused(let currentTime, let totalDuration):
            timeLabel.text = "\(formatTime(currentTime)) / \(formatTime(totalDuration))"
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }

        updateWaveformForState(state)
    }

    private func updateWaveformForState(_ state: VoiceRecordingState) {
        switch state {
        case .idle:
            waveformView.reset()
        case .recording:
            waveformView.startRecordingAnimation()
        case .completed:
            waveformView.stopRecordingAnimation()
        case .playing(let currentTime, let totalDuration):
            let progress = Float(currentTime / totalDuration)
            waveformView.updatePlaybackProgress(progress)
        case .paused:
            break
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Error Handling

    private func showPermissionDeniedAlert() {
        let alertInfo = permissionManager.createPermissionDeniedAlertInfo()
        let alert = UIAlertController(title: alertInfo.title, message: alertInfo.message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: alertInfo.settingsAction, style: .default) { _ in
            self.permissionManager.openAppSettings()
        })

        alert.addAction(UIAlertAction(title: alertInfo.cancelAction, style: .cancel))

        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Gesture Handlers

    @objc private func backgroundTapped() {
        handleCancelTapped()
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            if translation.y > 100 || velocity.y > 500 {
                handleCancelTapped()
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }

}
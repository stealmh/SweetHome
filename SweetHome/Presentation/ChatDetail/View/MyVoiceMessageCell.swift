//
//  MyVoiceMessageCell.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit
import SnapKit
import RxSwift

/// - MyVoiceMessageCell: 내가 보낸 음성 메시지 셀
final class MyVoiceMessageCell: UICollectionViewCell {

    // MARK: - UI Components

    private let messageView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.backgroundColor = .systemBlue
        return view
    }()

    private let voicePlayerView = VoiceMessagePlayerView()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()

    // MARK: - Properties

    private var disposeBag = DisposeBag()

    /// - 재생/일시정지 버튼 탭 이벤트 (외부에서 구독)
    var playPauseButtonTapped: Observable<VoiceMessageData?> {
        return voicePlayerView.playPauseButtonTapped
            .compactMap { [weak self] _ in
                return self?.currentVoiceData
            }
    }

    private var currentVoiceData: VoiceMessageData?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupVoicePlayerView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        currentVoiceData = nil
        voicePlayerView.updatePlaybackState(.idle)
    }

    private func setupUI() {
        contentView.addSubviews(messageView, timeLabel)
        messageView.addSubview(voicePlayerView)

        messageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(4)
            $0.trailing.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().inset(4)
            $0.width.equalTo(260)
            $0.leading.greaterThanOrEqualToSuperview().inset(60)
        }

        voicePlayerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
            $0.height.equalTo(40)
        }

        timeLabel.snp.makeConstraints {
            $0.bottom.equalTo(messageView.snp.bottom)
            $0.trailing.equalTo(messageView.snp.leading).offset(-4)
            $0.leading.greaterThanOrEqualToSuperview().inset(8)
        }
    }

    private func setupVoicePlayerView() {
        /// - 음성 플레이어 뷰를 내 메시지 스타일로 설정
        voicePlayerView.backgroundColor = .clear

        /// - 컴팩트 모드로 설정
        voicePlayerView.setCompactMode(true)
    }

    // MARK: - Public Methods

    /// - 음성 메시지로 셀 설정
    func configure(with voiceData: VoiceMessageData, message: LastChat, shouldShowTime: Bool = true) {
        currentVoiceData = voiceData

        /// - 음성 플레이어 설정
        voicePlayerView.configure(with: voiceData)

        /// - 시간 표시
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.createdAt)
        timeLabel.isHidden = !shouldShowTime
    }

    /// - 재생 상태 업데이트
    func updatePlaybackState(_ state: VoiceRecordingState) {
        voicePlayerView.updatePlaybackState(state)
    }

    /// - 재생 진행률 업데이트
    func updateProgress(_ progress: Float, currentTime: TimeInterval) {
        voicePlayerView.updateProgress(progress, currentTime: currentTime)
    }
}
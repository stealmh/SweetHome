//
//  AudioWaveformView.swift
//  SweetHome
//
//  Created by 김민호 on 9/27/25.
//

import UIKit
import SnapKit

/// - AudioWaveformView: 오디오 웨이브폼을 시각화하는 UI 컴포넌트
/// - 실시간 녹음 중과 정적 녹음 완료 상태 모두 지원
final class AudioWaveformView: UIView {

    // MARK: - UI Components

    private let stackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.alignment = .center
        v.distribution = .fillEqually
        v.spacing = 2
        return v
    }()

    // MARK: - Properties

    private var audioLevels: [AudioLevel] = []
    private var maxBars = 60  /// - 최대 표시할 막대 개수
    private var isAnimating = false

    private let minBarHeight: CGFloat = 2
    private let maxBarHeight: CGFloat = 40
    private let barWidth: CGFloat = 3
    private let animationDuration: TimeInterval = 0.1

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        setupInitialBars()
    }

    private func setupInitialBars() {
        /// - 초기 상태에서 최소 높이의 막대들로 채움
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for _ in 0..<maxBars {
            let bar = createBarView(height: minBarHeight)
            stackView.addArrangedSubview(bar)
        }
    }

    private func createBarView(height: CGFloat) -> UIView {
        let bar = UIView()
        bar.backgroundColor = .systemBlue
        bar.layer.cornerRadius = barWidth / 2

        bar.snp.makeConstraints {
            $0.width.equalTo(barWidth)
            $0.height.equalTo(height)
        }

        return bar
    }

    // MARK: - Public Interface

    /// - 실시간 녹음 중 오디오 레벨 업데이트
    func updateWithRealTimeLevel(_ level: Float) {
        guard !isAnimating else { return }

        let barHeight = minBarHeight + (maxBarHeight - minBarHeight) * CGFloat(level)

        /// - 새로운 막대를 맨 뒤에 추가
        let newBar = createBarView(height: barHeight)
        stackView.addArrangedSubview(newBar)

        /// - 최대 개수를 초과하면 맨 앞의 막대 제거
        if stackView.arrangedSubviews.count > maxBars {
            let firstBar = stackView.arrangedSubviews.first
            firstBar?.removeFromSuperview()
        }

        /// - 애니메이션으로 부드럽게 전환
        animateBarAppearance(newBar)
    }

    /// - 녹음 완료 후 전체 오디오 레벨 표시
    func updateWithCompletedLevels(_ levels: [AudioLevel]) {
        audioLevels = levels
        isAnimating = false

        /// - 기존 막대들 제거
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        /// - 오디오 레벨을 막대 개수에 맞게 샘플링
        let sampledLevels = sampleAudioLevels(levels, targetCount: maxBars)

        /// - 새로운 막대들 생성
        for level in sampledLevels {
            let barHeight = minBarHeight + (maxBarHeight - minBarHeight) * CGFloat(level.level)
            let bar = createBarView(height: barHeight)
            stackView.addArrangedSubview(bar)
        }
    }

    /// - 재생 진행률에 따른 시각적 피드백 (선택사항)
    func updatePlaybackProgress(_ progress: Float) {
        let progressIndex = Int(Float(stackView.arrangedSubviews.count) * progress)

        for (index, bar) in stackView.arrangedSubviews.enumerated() {
            if index <= progressIndex {
                bar.backgroundColor = .systemGreen  /// - 재생된 부분
            } else {
                bar.backgroundColor = .systemBlue   /// - 아직 재생되지 않은 부분
            }
        }
    }

    /// - 웨이브폼 초기화
    func reset() {
        audioLevels.removeAll()
        isAnimating = false
        setupInitialBars()
    }

    // MARK: - Private Methods

    private func animateBarAppearance(_ bar: UIView) {
        isAnimating = true
        bar.alpha = 0
        bar.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                bar.alpha = 1
                bar.transform = .identity
            },
            completion: { [weak self] _ in
                self?.isAnimating = false
            }
        )
    }

    private func sampleAudioLevels(_ levels: [AudioLevel], targetCount: Int) -> [AudioLevel] {
        guard levels.count > targetCount else {
            return levels
        }

        let step = levels.count / targetCount
        var sampledLevels: [AudioLevel] = []

        for i in 0..<targetCount {
            let index = i * step
            if index < levels.count {
                sampledLevels.append(levels[index])
            }
        }

        return sampledLevels
    }
}

// MARK: - Animation Extensions

extension AudioWaveformView {
    /// - 녹음 시작 시 애니메이션
    func startRecordingAnimation() {
        setupInitialBars()
    }

    /// - 녹음 중지 시 애니메이션
    func stopRecordingAnimation() {
        isAnimating = false
    }
}
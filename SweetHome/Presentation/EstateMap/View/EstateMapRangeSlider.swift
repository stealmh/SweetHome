//
//  EstateMapRangeSlider.swift
//  SweetHome
//
//  Created by 김민호 on 8/11/25.
//

import UIKit
import SnapKit

class EstateMapRangeSlider: UIControl {
    
    // MARK: - Properties
    var minimumValue: Float = 0.0 {
        didSet { updateLayerFrames() }
    }
    
    var maximumValue: Float = 100.0 {
        didSet { updateLayerFrames() }
    }
    
    var lowerValue: Float = 20.0 {
        didSet { isDragging ? updateThumbsAndRangeOnly() : updateLayerFrames() }
    }
    
    var upperValue: Float = 80.0 {
        didSet { isDragging ? updateThumbsAndRangeOnly() : updateLayerFrames() }
    }
    
    // MARK: - UI Properties
    private let trackHeight: CGFloat = 6.0
    private let thumbSize: CGFloat = 20.0
    
    private let trackLayer = CALayer()
    private let rangeTrackLayer = CAGradientLayer()
    private let lowerThumbLayer = CALayer()
    private let upperThumbLayer = CALayer()
    private let lowerThumbBorderLayer = CAGradientLayer()
    private let upperThumbBorderLayer = CAGradientLayer()
    
    private var previousLocation = CGPoint()
    private var activeThumb: ThumbType = .none
    private var isDragging: Bool = false
    
    private enum ThumbType {
        case lower, upper, none
    }
    
    // MARK: - Colors
    private let trackTintColor = SHColor.GrayScale.gray_45
    private let rangeTintColor = UIColor.systemBlue
    private let thumbTintColor = UIColor.white
    private let thumbBorderStartColor = SHColor.Brand.brightWood
    private let thumbBorderEndColor = SHColor.Brand.deepWood
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)
        isDragging = true
        
        if lowerThumbLayer.frame.contains(previousLocation) {
            activeThumb = .lower
            return true
        } else if upperThumbLayer.frame.contains(previousLocation) {
            activeThumb = .upper
            return true
        } else {
            let lowerDistance = abs(previousLocation.x - positionForValue(lowerValue))
            let upperDistance = abs(previousLocation.x - positionForValue(upperValue))
            
            if lowerDistance < upperDistance {
                activeThumb = .lower
            } else {
                activeThumb = .upper
            }
            return true
        }
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let newValue = valueForPosition(location.x)
        
        switch activeThumb {
        case .lower:
            lowerValue = max(minimumValue, min(newValue, upperValue))
        case .upper:
            upperValue = max(lowerValue, min(newValue, maximumValue))
        case .none:
            break
        }
        
        previousLocation = location
        sendActions(for: .valueChanged)
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isDragging = false
        activeThumb = .none
        sendActions(for: .valueChanged)
    }
}

// MARK: - Setup
private extension EstateMapRangeSlider {
    /// - 슬라이더의 모든 레이어 초기 설정
    func setupLayers() {
        trackLayer.backgroundColor = trackTintColor.cgColor
        layer.addSublayer(trackLayer)
        
        setupGradientLayer()
        layer.addSublayer(rangeTrackLayer)
        
        setupThumbLayers()
    }
    /// - 그라데이션 레이어의 색상, 방향 설정
    func setupGradientLayer() {
        rangeTrackLayer.colors = [
            SHColor.Brand.brightWood.cgColor,
            SHColor.Brand.deepWood.cgColor
        ]
        rangeTrackLayer.startPoint = CGPoint(x: 0, y: 0.5)
        rangeTrackLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }
    /// - 상하 두 개의 thumb 레이어 설정
    func setupThumbLayers() {
        configureThumb(lowerThumbLayer, borderColor: thumbBorderStartColor)
        configureThumb(upperThumbLayer, borderColor: thumbBorderEndColor)
    }
    /// - 개별 thumb 레이어의 스타일을 설정
    func configureThumb(_ thumbLayer: CALayer, borderColor: UIColor) {
        thumbLayer.backgroundColor = thumbTintColor.cgColor
        thumbLayer.borderColor = borderColor.cgColor
        thumbLayer.borderWidth = 2.0
        thumbLayer.cornerRadius = thumbSize / 2
        layer.addSublayer(thumbLayer)
    }
}

// MARK: - Layout Update
private extension EstateMapRangeSlider {
    /// - 모든 레이어의 프레임 업데이트
    func updateLayerFrames() {
        let thumbRadius = thumbSize / 2.0
        let trackY = (bounds.height - trackHeight) / 2.0
        
        updateTrackFrame(trackY: trackY, thumbRadius: thumbRadius)
        updateRangeAndThumbFrames(trackY: trackY, thumbRadius: thumbRadius)
    }
    /// - 배경 트랙의 프레임 업데이트
    func updateTrackFrame(trackY: CGFloat, thumbRadius: CGFloat) {
        trackLayer.frame = CGRect(
            x: thumbRadius,
            y: trackY,
            width: bounds.width - thumbSize,
            height: trackHeight
        )
        trackLayer.cornerRadius = trackHeight / 2.0
    }
    /// - 선택 범위와 thumb의 프레임을 업데이트
    func updateRangeAndThumbFrames(trackY: CGFloat, thumbRadius: CGFloat) {
        let lowerPosition = positionForValue(lowerValue)
        let upperPosition = positionForValue(upperValue)
        
        rangeTrackLayer.frame = CGRect(
            x: lowerPosition,
            y: trackY,
            width: upperPosition - lowerPosition,
            height: trackHeight
        )
        rangeTrackLayer.cornerRadius = trackHeight / 2.0
        
        lowerThumbLayer.frame = CGRect(
            x: lowerPosition - thumbRadius,
            y: (bounds.height - thumbSize) / 2.0,
            width: thumbSize,
            height: thumbSize
        )
        
        upperThumbLayer.frame = CGRect(
            x: upperPosition - thumbRadius,
            y: (bounds.height - thumbSize) / 2.0,
            width: thumbSize,
            height: thumbSize
        )
    }
    /// - 드래그 중 필요한 레이어만 업데이트
    func updateThumbsAndRangeOnly() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let thumbRadius = thumbSize / 2.0
        let trackY = (bounds.height - trackHeight) / 2.0
        let lowerPosition = positionForValue(lowerValue)
        let upperPosition = positionForValue(upperValue)
        
        rangeTrackLayer.frame = CGRect(
            x: lowerPosition,
            y: trackY,
            width: upperPosition - lowerPosition,
            height: trackHeight
        )
        
        lowerThumbLayer.frame = CGRect(
            x: lowerPosition - thumbRadius,
            y: (bounds.height - thumbSize) / 2.0,
            width: thumbSize,
            height: thumbSize
        )
        
        upperThumbLayer.frame = CGRect(
            x: upperPosition - thumbRadius,
            y: (bounds.height - thumbSize) / 2.0,
            width: thumbSize,
            height: thumbSize
        )
        
        CATransaction.commit()
    }
}

// MARK: - Value Conversion
private extension EstateMapRangeSlider {
    /// - Float 값을 화면 좌표로 변환하는 함수
    func positionForValue(_ value: Float) -> CGFloat {
        let thumbRadius = thumbSize / 2.0
        let availableWidth = bounds.width - thumbSize
        let valueRange = maximumValue - minimumValue
        let position = CGFloat(value - minimumValue) / CGFloat(valueRange) * availableWidth + thumbRadius
        return position
    }
    /// - 화면 좌표를 Float 값으로 변환하는 함수
    func valueForPosition(_ position: CGFloat) -> Float {
        let thumbRadius = thumbSize / 2.0
        let availableWidth = bounds.width - thumbSize
        let valueRange = maximumValue - minimumValue
        let value = Float((position - thumbRadius) / availableWidth) * valueRange + minimumValue
        return max(minimumValue, min(maximumValue, value))
    }
}

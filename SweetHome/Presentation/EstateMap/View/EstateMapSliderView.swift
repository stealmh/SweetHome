//
//  EstateMapSliderView.swift
//  SweetHome
//
//  Created by 김민호 on 8/11/25.
//

import UIKit
import SnapKit

class EstateMapSliderView: UIView {
    private var tipStartX: CGFloat = 0
    private let tipWidth: CGFloat = 12
    private let tipHeight: CGFloat = 6
    private let cornerRadius: CGFloat = 16
    private let tipCornerRadius: CGFloat = 0.3
    private let viewColor: UIColor = .white
    private let borderColor: UIColor = SHColor.GrayScale.gray_45
    private let borderWidth: CGFloat = 1
    
    private var shapeLayer: CAShapeLayer?
    
    private let componentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading
        stackView.spacing = 0
        return stackView
    }()
    
    private let rangeSlider: EstateMapRangeSlider = {
        let slider = EstateMapRangeSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.lowerValue = 20
        slider.upperValue = 80
        return slider
    }()
    
    private let component1 = EstateMapSliderComponent()
    private let component2 = EstateMapSliderComponent()
    private let component3 = EstateMapSliderComponent()
    private let component4 = EstateMapSliderComponent()
    
    private let rangeTooltip = EstateMapRangeTooltip()
    
    private var currentUnit: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.layer.masksToBounds = false
        self.isHidden = true
        
        addContentView()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawShape()
    }
}

// MARK: - Public Interface
extension EstateMapSliderView {
    /// - tip 좌표를 업데이트하고 뷰를 다시 그림
    func updateTipStartX(_ newTipStartX: CGFloat) {
        self.tipStartX = newTipStartX
        setNeedsLayout()
    }
    /// - 슬라이더 범위와 스케일을 외부에서 설정할 수 있는 함수
    func configureSlider(
        minimumValue: Float,
        maximumValue: Float,
        lowerValue: Float,
        upperValue: Float,
        unit: String = ""
    ) {
        rangeSlider.minimumValue = minimumValue
        rangeSlider.maximumValue = maximumValue
        rangeSlider.lowerValue = lowerValue
        rangeSlider.upperValue = upperValue
        
        // 현재 단위 저장
        currentUnit = unit
        
        // 슬라이더 값 변경 이벤트 추가
        rangeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        // 초기 툴팁 업데이트
        updateTooltip()
        
        // 레이아웃이 완료된 후 스케일 값과 툴팁 위치 업데이트
        DispatchQueue.main.async {
            self.updateScaleValuesWithAlignment(min: minimumValue, max: maximumValue, unit: unit)
            self.updateTooltipPosition()
        }
    }
    /// - 스케일 값들을 4개 구간으로 나누어 업데이트 (기존 메서드 유지)
    func updateScaleValues(min: Float, max: Float, unit: String = "") {
        let range = max - min
        let quarter = min + (range * 0.25)
        let half = min + (range * 0.5)
        
        let minValue = formatValue(min, unit: unit)
        let quarterValue = formatValue(quarter, unit: unit)
        let halfValue = formatValue(half, unit: unit)
        let maxValue = formatValue(max, unit: unit)
        
        component1.configure(value: minValue)
        component2.configure(value: quarterValue)
        component3.configure(value: halfValue)
        component4.configure(value: maxValue)
    }
    
    /// - 슬라이더 트랙과 정확히 정렬된 스케일 값 업데이트 (4등분: 0%, 33.33%, 66.67%, 100%)
    private func updateScaleValuesWithAlignment(min: Float, max: Float, unit: String = "") {
        guard rangeSlider.bounds.width > 0 else {
            // 레이아웃이 아직 완료되지 않은 경우 다시 시도
            DispatchQueue.main.async {
                self.updateScaleValuesWithAlignment(min: min, max: max, unit: unit)
            }
            return
        }
        
        // EstateMapRangeSlider와 동일한 로직으로 위치 계산
        let thumbSize: CGFloat = 20.0 // EstateMapRangeSlider의 thumbSize와 동일
        let thumbRadius = thumbSize / 2.0
        let availableWidth = rangeSlider.bounds.width - thumbSize
        let valueRange = max - min
        
        // 4등분 구분점의 정확한 위치에 해당하는 값 계산 (0%, 33.33%, 66.67%, 100%)
        let positions: [Float] = [0.0, 1.0/3.0, 2.0/3.0, 1.0]
        
        let values = positions.map { relativePosition in
            // EstateMapRangeSlider.positionForValue와 동일한 로직
            let targetPosition = CGFloat(relativePosition) * availableWidth + thumbRadius
            
            // position을 다시 value로 변환
            let value = Float((targetPosition - thumbRadius) / availableWidth) * valueRange + min
            return value
        }
        
        component1.configure(value: "최소")
        component2.configure(value: formatValue(values[1], unit: unit))
        component3.configure(value: formatValue(values[2], unit: unit))
        component4.configure(value: "최대")
    }
    /// - 현재 슬라이더 값을 가져오는 함수
    func getCurrentValues() -> (lower: Float, upper: Float) {
        return (rangeSlider.lowerValue, rangeSlider.upperValue)
    }
    /// - 슬라이더 값 변경 이벤트를 처리하는 함수를 외부에서 설정
    func addSliderValueChangedTarget(_ target: Any?, action: Selector) {
        rangeSlider.addTarget(target, action: action, for: .valueChanged)
    }
    
    /// - 현재 선택된 범위를 텍스트로 가져오는 함수 (필터 버튼에 표시용)
    func getRangeText() -> String {
        let lowerValue = Int(round(rangeSlider.lowerValue))
        let upperValue = Int(round(rangeSlider.upperValue))
        let minValue = Int(round(rangeSlider.minimumValue))
        let maxValue = Int(round(rangeSlider.maximumValue))
        
        // 최소값부터 선택한 경우: ~upperValue 형식
        if lowerValue == minValue && upperValue < maxValue {
            if currentUnit == "만원" && upperValue >= 1000 {
                let formattedUpper = formatLargeValue(upperValue)
                return "~\(formattedUpper)"
            } else {
                return "~\(upperValue)\(currentUnit)"
            }
        }
        // 최대값까지 선택한 경우: lowerValue~ 형식
        else if upperValue == maxValue && lowerValue > minValue {
            if currentUnit == "만원" && lowerValue >= 1000 {
                let formattedLower = formatLargeValue(lowerValue)
                return "\(formattedLower)~"
            } else {
                return "\(lowerValue)\(currentUnit)~"
            }
        }
        // 최소에서 최대까지 전체 선택한 경우: 전체 형식
        else if lowerValue == minValue && upperValue == maxValue {
            return "전체"
        }
        // 일반적인 범위 선택: lowerValue~upperValue 형식
        else {
            if currentUnit == "만원" && lowerValue >= 1000 {
                let formattedLower = formatLargeValue(lowerValue)
                let formattedUpper = formatLargeValue(upperValue)
                return "\(formattedLower)~\(formattedUpper)"
            } else {
                return "\(lowerValue)\(currentUnit)~\(upperValue)\(currentUnit)"
            }
        }
    }
    
    /// - 큰 값을 간략하게 포맷팅하는 함수
    private func formatLargeValue(_ value: Int) -> String {
        if currentUnit == "만원" && value >= 1000 {
            let thousandValue = value / 1000
            let remainder = (value % 1000) / 100
            
            if remainder == 0 {
                return "\(thousandValue)천만"
            } else {
                return "\(thousandValue)천\(remainder)백만"
            }
        } else {
            return "\(value)\(currentUnit)"
        }
    }
    
    /// - 슬라이더 값이 변경될 때 호출되는 함수
    @objc private func sliderValueChanged() {
        updateTooltip()
        updateTooltipPosition()
    }
    
    /// - 툴팁 업데이트
    private func updateTooltip() {
        rangeTooltip.updateRange(
            lowerValue: rangeSlider.lowerValue,
            upperValue: rangeSlider.upperValue,
            minValue: rangeSlider.minimumValue,
            maxValue: rangeSlider.maximumValue,
            unit: currentUnit
        )
    }
    
    /// - 슬라이더 중앙 위치에 따라 툴팁 위치 업데이트
    private func updateTooltipPosition() {
        guard rangeSlider.bounds.width > 0 else { return }
        
        // EstateMapRangeSlider와 동일한 로직으로 위치 계산
        let thumbSize: CGFloat = 20.0
        let thumbRadius = thumbSize / 2.0
        let availableWidth = rangeSlider.bounds.width - thumbSize
        let valueRange = rangeSlider.maximumValue - rangeSlider.minimumValue
        
        // lower와 upper thumb의 위치 계산
        let lowerPosition = CGFloat(rangeSlider.lowerValue - rangeSlider.minimumValue) / CGFloat(valueRange) * availableWidth + thumbRadius
        let upperPosition = CGFloat(rangeSlider.upperValue - rangeSlider.minimumValue) / CGFloat(valueRange) * availableWidth + thumbRadius
        
        // 슬라이더 범위의 중앙 위치 계산
        let centerPosition = (lowerPosition + upperPosition) / 2.0
        
        // 툴팁을 슬라이더 범위의 중앙에 맞춰 위치 조정
        rangeTooltip.snp.remakeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalTo(rangeSlider.snp.leading).offset(centerPosition)
            $0.height.equalTo(25)
        }
    }
}

// MARK: - Setup
private extension EstateMapSliderView {
    /// - 콘텐츠 뷰와 슬라이더 구성 요소들을 설정
    func addContentView() {
        let contentView = UIView()
        contentView.backgroundColor = .clear
        
        addSubviewsToContentView(contentView)
        setupComponentStackView()
        addDebugColors()
        
        self.addSubview(contentView)
        setupContentViewConstraints(contentView)
        
        updateScaleValues(min: 0, max: 100, unit: "")
    }
    /// - 콘텐츠 뷰에 서브뷰들을 추가
    func addSubviewsToContentView(_ contentView: UIView) {
        contentView.addSubview(rangeTooltip)
        contentView.addSubview(componentStackView)
        contentView.addSubview(rangeSlider)
    }
    
    /// - 컴포넌트 스택뷰에 4개의 슬라이더 컴포넌트를 추가
    func setupComponentStackView() {
        componentStackView.addArrangedSubview(component1)
        componentStackView.addArrangedSubview(component2)
        componentStackView.addArrangedSubview(component3)
        componentStackView.addArrangedSubview(component4)
    }
    
    //TODO: 디버그용 색상처리 제거
    func addDebugColors() {
        component1.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        component2.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        component3.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        component4.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
    }
}

/// MARK: - Layout
private extension EstateMapSliderView {
    /// - 콘텐츠 뷰와 내부 구성 요소들의 제약 조건을 설정
    func setupContentViewConstraints(_ contentView: UIView) {
        setupContentViewFrame(contentView)
        setupRangeSliderConstraints()
        setupComponentStackViewConstraints()
        setupRangeTooltipConstraints()
    }
    /// - 메인 콘텐츠 뷰의 프레임을 설정 (동적 높이)
    func setupContentViewFrame(_ contentView: UIView) {
        contentView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().inset(8)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            // 높이는 내부 요소들에 의해 자동으로 결정됨 (동적)
        }
    }
    /// - 범위 슬라이더의 제약 조건을 설정
    func setupRangeSliderConstraints() {
        rangeSlider.snp.makeConstraints {
            $0.top.equalTo(rangeTooltip.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(25)
            $0.height.equalTo(16)
        }
    }
    /// - 컴포넌트들을 슬라이더 트랙과 정확히 정렬하여 배치
    func setupComponentStackViewConstraints() {
        // StackView를 사용하지 않고 개별 컴포넌트를 정확히 배치
        let contentView = componentStackView.superview!
        
        // StackView 제거하고 개별 컴포넌트를 직접 추가
        componentStackView.removeFromSuperview()
        contentView.addSubviews(component1, component2, component3, component4)
        
        let thumbRadius: CGFloat = 10.0 // EstateMapRangeSlider의 thumbSize/2
        
        // 첫 번째 컴포넌트: 슬라이더 트랙 시작점
        component1.snp.makeConstraints {
            $0.top.equalTo(rangeSlider.snp.bottom)
            $0.bottom.equalTo(contentView).inset(8)
            $0.centerX.equalTo(rangeSlider.snp.leading).offset(thumbRadius)
        }
        
        // 네 번째 컴포넌트: 슬라이더 트랙 끝점
        component4.snp.makeConstraints {
            $0.top.equalTo(rangeSlider.snp.bottom)
            $0.bottom.equalTo(contentView).inset(8)
            $0.centerX.equalTo(rangeSlider.snp.trailing).offset(-thumbRadius)
        }
        
        /// - 세 번째 컴포넌트: 레이아웃 완료 후 66.67% 지점에 배치
        component3.snp.makeConstraints {
            $0.top.equalTo(rangeSlider.snp.bottom)
            $0.bottom.equalTo(contentView).inset(8)
            $0.width.greaterThanOrEqualTo(20)
        }
        
        /// - 두 번째 컴포넌트: 레이아웃 완료 후 33.33% 지점에 배치
        component2.snp.makeConstraints {
            $0.top.equalTo(rangeSlider.snp.bottom)
            $0.bottom.equalTo(contentView).inset(8)
            $0.width.greaterThanOrEqualTo(20)
        }
        
        /// - 레이아웃 완료 후 33.33%, 66.67% 지점에 배치 (4등분)
        DispatchQueue.main.async {
            self.positionMiddleComponents()
        }
    }
    
    /// - 두 번째(33.33%), 세 번째(66.67%) 컴포넌트를 정확한 위치에 배치 후 slider 위치 조정
    private func positionMiddleComponents() {
        guard rangeSlider.bounds.width > 0 else {
            DispatchQueue.main.async {
                self.positionMiddleComponents()
            }
            return
        }
        
        let thumbRadius: CGFloat = 10.0
        let trackWidth = rangeSlider.bounds.width - 2 * thumbRadius
        let oneThirdPoint = thumbRadius + trackWidth * (1.0/3.0)
        let twoThirdPoint = thumbRadius + trackWidth * (2.0/3.0)
        
        let contentView = rangeSlider.superview!
        
        /// - 두 번째 컴포넌트 (33.33% 지점)
        component2.snp.remakeConstraints {
            $0.top.equalTo(rangeSlider.snp.bottom)
            $0.bottom.equalTo(contentView).inset(8)
            $0.centerX.equalTo(rangeSlider.snp.leading).offset(oneThirdPoint)
        }
        
        /// - 세 번째 컴포넌트 (66.67% 지점)
        component3.snp.remakeConstraints {
            $0.top.equalTo(rangeSlider.snp.bottom)
            $0.bottom.equalTo(contentView).inset(8)
            $0.centerX.equalTo(rangeSlider.snp.leading).offset(twoThirdPoint)
        }
    }
    
    /// - 범위 툴팁의 제약 조건을 설정
    func setupRangeTooltipConstraints() {
        rangeTooltip.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.height.equalTo(25) // 툴팁 25px
        }
    }
}

/// MARK: - Drawing
private extension EstateMapSliderView {
    /// - 말풍선 모양의 커스텀 셰이프를 그리는 함수
    func drawShape() {
        shapeLayer?.removeFromSuperlayer()
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - tipHeight)
        let path = createShapePath(for: rect)
        
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = viewColor.cgColor
        shape.strokeColor = borderColor.cgColor
        shape.lineWidth = borderWidth
        
        layer.insertSublayer(shape, at: 0)
        shapeLayer = shape
    }
    /// - 말풍선 모양의 베지어 패스를 생성
    func createShapePath(for rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        addTipPath(to: path)
        addTopRightCorner(to: path, rect: rect)
        addBottomRightCorner(to: path, rect: rect)
        addBottomLeftCorner(to: path, rect: rect)
        addTopLeftCorner(to: path, rect: rect)
        
        path.close()
        return path
    }
    /// - 말풍선 tip 부분의 패스를 추가
    func addTipPath(to path: UIBezierPath) {
        path.addLine(to: CGPoint(x: tipStartX - tipCornerRadius, y: 0))
        
        path.addQuadCurve(
            to: CGPoint(x: tipStartX + tipWidth / 2, y: -tipHeight + tipCornerRadius),
            controlPoint: CGPoint(x: tipStartX + tipWidth / 4, y: -tipHeight + tipCornerRadius / 2)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: tipStartX + tipWidth - tipCornerRadius, y: 0),
            controlPoint: CGPoint(x: tipStartX + tipWidth * 3 / 4, y: -tipHeight + tipCornerRadius / 2)
        )
    }
    /// - 우측 상단 모서리의 패스를 추가
    func addTopRightCorner(to path: UIBezierPath, rect: CGRect) {
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(withCenter: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(-Double.pi / 2),
                    endAngle: 0,
                    clockwise: true)
    }
    /// - 우측 하단 모서리의 패스를 추가
    func addBottomRightCorner(to path: UIBezierPath, rect: CGRect) {
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addArc(withCenter: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: 0,
                    endAngle: CGFloat(Double.pi / 2),
                    clockwise: true)
    }
    /// - 좌측 하단 모서리의 패스를 추가
    func addBottomLeftCorner(to path: UIBezierPath, rect: CGRect) {
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(Double.pi / 2),
                    endAngle: CGFloat(Double.pi),
                    clockwise: true)
    }
    /// - 좌측 상단 모서리의 패스를 추가
    func addTopLeftCorner(to path: UIBezierPath, rect: CGRect) {
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(Double.pi),
                    endAngle: CGFloat(-Double.pi / 2),
                    clockwise: true)
    }
}

/// MARK: - Utilities
private extension EstateMapSliderView {
    /// - Float 값을 문자열로 포맷팅 (정수로 반올림)
    func formatValue(_ value: Float, unit: String) -> String {
        let roundedValue = Int(round(value))
        return "\(roundedValue)\(unit)"
    }
}

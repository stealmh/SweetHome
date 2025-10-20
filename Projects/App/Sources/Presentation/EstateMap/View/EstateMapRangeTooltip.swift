//
//  EstateMapRangeTooltip.swift
//  SweetHome
//
//  Created by 김민호 on 8/11/25.
//

import UIKit
import SnapKit

class EstateMapRangeTooltip: UIView {
    private let tipWidth: CGFloat = 8
    private let tipHeight: CGFloat = 4
    private let cornerRadius: CGFloat = 6
    private let tipCornerRadius: CGFloat = 0.3
    private let viewColor: UIColor = .white
    private let borderColor: UIColor = SHColor.GrayScale.gray_45
    private let borderWidth: CGFloat = 1
    
    private var shapeLayer: CAShapeLayer?
    
    private let rangeLabel: UILabel = {
        let label = UILabel()
        label.setFont(.pretendard(.medium), size: .caption2)
        label.textColor = SHColor.GrayScale.gray_90
        label.textAlignment = .center
        label.text = "0~100"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        self.backgroundColor = .clear
        self.layer.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawTooltipShape()
    }
    
    private func setupUI() {
        addSubview(rangeLabel)
    }
    
    private func setupConstraints() {
        rangeLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(6)
            $0.bottom.equalToSuperview().inset(6 + tipHeight)
        }
    }
    
    /// - 범위 텍스트 업데이트
    func updateRange(lowerValue: Float, upperValue: Float, minValue: Float, maxValue: Float, unit: String) {
        let lowerInt = Int(round(lowerValue))
        let upperInt = Int(round(upperValue))
        let minInt = Int(round(minValue))
        let maxInt = Int(round(maxValue))
        
        // 최소값부터 선택한 경우: ~upperValue 형식
        if lowerInt == minInt && upperInt < maxInt {
            let formattedUpper = formatValue(upperValue, unit: unit)
            rangeLabel.text = "~\(formattedUpper)"
        }
        // 최대값까지 선택한 경우: lowerValue~ 형식
        else if upperInt == maxInt && lowerInt > minInt {
            let formattedLower = formatValue(lowerValue, unit: unit)
            rangeLabel.text = "\(formattedLower)~"
        }
        // 최소에서 최대까지 전체 선택한 경우: 전체 형식
        else if lowerInt == minInt && upperInt == maxInt {
            rangeLabel.text = "전체"
        }
        // 일반적인 범위 선택: lowerValue~upperValue 형식
        else {
            let formattedLower = formatValue(lowerValue, unit: unit)
            let formattedUpper = formatValue(upperValue, unit: unit)
            rangeLabel.text = "\(formattedLower)~\(formattedUpper)"
        }
    }
    
    private func formatValue(_ value: Float, unit: String) -> String {
        let roundedValue = Int(round(value))
        
        if unit == "만원" && roundedValue >= 1000 {
            let thousandValue = roundedValue / 1000
            let remainder = (roundedValue % 1000) / 100
            
            if remainder == 0 {
                return "\(thousandValue)천만"
            } else {
                return "\(thousandValue)천\(remainder)백만"
            }
        } else {
            return "\(roundedValue)\(unit)"
        }
    }
}

// MARK: - Drawing
private extension EstateMapRangeTooltip {
    /// - 말풍선 모양의 툴팁을 그리는 함수
    func drawTooltipShape() {
        shapeLayer?.removeFromSuperlayer()
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - tipHeight)
        let path = createTooltipPath(for: rect)
        
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = viewColor.cgColor
        shape.strokeColor = borderColor.cgColor
        shape.lineWidth = borderWidth
        
        layer.insertSublayer(shape, at: 0)
        shapeLayer = shape
    }
    
    /// - 말풍선 모양의 베지어 패스를 생성 (tip이 하단 중앙에 위치)
    func createTooltipPath(for rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let tipStartX = rect.width / 2 - tipWidth / 2
        
        /// - 좌측 상단에서 시작
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        /// - 상단 라인
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        
        /// - 우측 상단 모서리
        path.addArc(withCenter: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(-Double.pi / 2),
                    endAngle: 0,
                    clockwise: true)
        
        /// - 우측 라인
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        
        /// - 우측 하단 모서리
        path.addArc(withCenter: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: 0,
                    endAngle: CGFloat(Double.pi / 2),
                    clockwise: true)
        
        /// - 하단 우측에서 tip 시작점까지
        path.addLine(to: CGPoint(x: tipStartX + tipWidth + tipCornerRadius, y: rect.height))
        
        /// - tip 그리기 (하단 중앙)
        addTipPath(to: path, tipStartX: tipStartX, rectHeight: rect.height)
        
        /// - 하단 좌측
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        
        /// - 좌측 하단 모서리
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(Double.pi / 2),
                    endAngle: CGFloat(Double.pi),
                    clockwise: true)
        
        /// - 좌측 라인
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        
        /// - 좌측 상단 모서리
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(Double.pi),
                    endAngle: CGFloat(-Double.pi / 2),
                    clockwise: true)
        
        path.close()
        return path
    }
    
    /// - 하단 중앙에 tip을 그리는 함수
    func addTipPath(to path: UIBezierPath, tipStartX: CGFloat, rectHeight: CGFloat) {
        path.addQuadCurve(
            to: CGPoint(x: tipStartX + tipWidth / 2, y: rectHeight + tipHeight - tipCornerRadius),
            controlPoint: CGPoint(x: tipStartX + tipWidth * 3 / 4, y: rectHeight + tipHeight - tipCornerRadius / 2)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: tipStartX - tipCornerRadius, y: rectHeight),
            controlPoint: CGPoint(x: tipStartX + tipWidth / 4, y: rectHeight + tipHeight - tipCornerRadius / 2)
        )
    }
}

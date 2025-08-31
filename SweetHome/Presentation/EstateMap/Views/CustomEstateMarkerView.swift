//
//  CustomEstateMarkerView.swift
//  SweetHome
//
//  Created by 김민호 on 8/12/25.
//

import UIKit
import SnapKit

/// 단순한 말풍선 모양 매물 마커 뷰
class CustomEstateMarkerView: UIView {
    
    private let thumbnailView: UIImageView = {
        let v = UIImageView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 4
        return v
    }()
    
    // MARK: - UI Components
    private let priceLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.semiBold), size: .caption2)
        v.textColor = SHColor.GrayScale.gray_60
        v.textAlignment = .left
        v.numberOfLines = 1
        return v
    }()
    
    // MARK: - Callback
    var onImageLoaded: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        applyStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        applyStyle()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = .clear
        
        // 서브뷰 추가 순서: 말풍선 배경이 먼저 그려지고 그 위에 이미지와 라벨
        addSubviews(thumbnailView, priceLabel)
        
        // 썸네일 이미지가 배경 위에 보이도록 z-order 조정
        bringSubviewToFront(thumbnailView)
        bringSubviewToFront(priceLabel)
    }
    
    private func setupConstraints() {
        thumbnailView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(60) // 정사각형 보장
        }
        
        priceLabel.snp.makeConstraints {
            $0.top.equalTo(thumbnailView.snp.bottom).offset(3).priority(.high)
            $0.leading.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().inset(6)
            $0.bottom.equalToSuperview().inset(12).priority(.required) // 12px 여백 강제
        }
    }
    
    // MARK: - Configuration Methods
    func configure(with estate: EstateGeoLocationDataResponse) {
        let priceText = formatEstatePrice(deposit: estate.deposit, monthlyRent: estate.monthly_rent)
        priceLabel.text = priceText
        
        // 썸네일 이미지 로드 (기본 이미지로 fallback)
        if let thumbnailURL = estate.thumbnails.first, !thumbnailURL.isEmpty {
            print("🖼️ 마커 이미지 로딩 시작: \(thumbnailURL)")
            
            thumbnailView.setAuthenticatedImage(with: thumbnailURL) { [weak self] in
                print("✅ 마커 이미지 로딩 콜백 호출")
                print("🖼️ 썸네일뷰 이미지 확인: \(self?.thumbnailView.image != nil ? "이미지 있음" : "이미지 없음")")
                
                if let image = self?.thumbnailView.image {
                    print("🖼️ 현재 설정된 이미지 크기: \(image.size)")
                    // SF Symbol인지 확인
                    if image.isSymbolImage {
                        print("🔍 현재 이미지는 SF Symbol (기본 이미지)")
                    } else {
                        print("🔍 현재 이미지는 실제 로딩된 이미지")
                    }
                } else {
                    print("❌ 썸네일뷰에 이미지가 설정되지 않음")
                }
                
                self?.onImageLoaded?()
            }
        } else {
            print("🏠 기본 이미지 사용 (썸네일 없음)")
            // 썸네일이 없는 경우 기본 이미지 설정
            thumbnailView.image = SHAsset.Default.defaultEstate
            thumbnailView.tintColor = SHColor.Brand.deepCream
            // 기본 이미지도 로드 완료로 처리
            onImageLoaded?()
        }
        
        applyStyle()
    }
    
    private func formatEstatePrice(deposit: Int, monthlyRent: Int) -> String {
        let depositText: String
        
        // 보증금 포맷팅
        if deposit >= 100000000 {  // 1억 이상
            depositText = "\(deposit/100000000)억"
        } else if deposit >= 10000 {  // 1만 이상
            depositText = "\(deposit/10000)"
        } else {
            depositText = "\(deposit)"
        }
        
        // 월세 포맷팅
        if monthlyRent > 0 {
            let monthlyText = monthlyRent >= 10000 ? "\(monthlyRent/10000)" : "\(monthlyRent)"
            return "\(depositText)/\(monthlyText)"
        } else {
            return depositText
        }
    }
    
    private func applyStyle() {
        // 배경은 투명으로 설정 (draw에서 직접 그리기)
        backgroundColor = .clear
        
        // 그림자 효과 (말풍선 전체에)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.3
        
        // 다시 그리기
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(SHColor.GrayScale.gray_0.cgColor)
        
        // 말풍선 메인 부분 그리기 (둥근 사각형)
        let bubbleHeight: CGFloat = rect.height - 8  // 꼬리 높이만큼 빼기
        let bubbleRect = CGRect(x: 0, y: 0, width: rect.width, height: bubbleHeight)
        let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 15)
        bubblePath.fill()
        
        // 말풍선 꼬리 그리기
        let tailWidth: CGFloat = 12
        let tailHeight: CGFloat = 8
        let startX = rect.midX - tailWidth/2
        let startY = bubbleHeight
        
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: startX, y: startY))
        tailPath.addLine(to: CGPoint(x: rect.midX, y: startY + tailHeight))
        tailPath.addLine(to: CGPoint(x: startX + tailWidth, y: startY))
        tailPath.close()
        tailPath.fill()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 말풍선 꼬리 다시 그리기 위해
        setNeedsDisplay()
    }
}


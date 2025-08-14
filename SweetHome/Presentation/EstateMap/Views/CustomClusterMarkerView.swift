//
//  CustomClusterMarkerView.swift
//  SweetHome
//
//  Created by 김민호 on 8/12/25.
//

import UIKit
import SnapKit

/// 단순한 원형 클러스터 마커 뷰
class CustomClusterMarkerView: UIView {
    
    // MARK: - UI Components
    private let countLabel = UILabel()
    
    // MARK: - Properties
    private var itemCount: Int = 0
    
    // MARK: - Initialization
    init(count: Int) {
        self.itemCount = count
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // 배경을 SHColor.Brand.deepCream으로 설정
        backgroundColor = SHColor.Brand.deepCream
        
        // 개수 레이블 설정
        countLabel.font = UIFont.boldSystemFont(ofSize: 14)
        countLabel.textColor = .white
        countLabel.textAlignment = .center
        countLabel.text = formatCount(itemCount)
        addSubview(countLabel)
    }
    
    private func setupConstraints() {
        countLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.edges.equalToSuperview().inset(4)
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return "\(count / 1000)K+"
        } else if count >= 100 {
            return "99+"
        } else {
            return "\(count)"
        }
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        // 원형으로 만들기
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
    
    // MARK: - Configuration Methods
    func updateCount(_ count: Int) {
        itemCount = count
        countLabel.text = formatCount(count)
    }
}

// MARK: - ClusterSize Enum
enum ClusterSize {
    case small   // 2-9개
    case medium  // 10-49개  
    case large   // 50개 이상
    
    var diameter: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 50
        case .large: return 60
        }
    }
    
    static func fromCount(_ count: Int) -> ClusterSize {
        switch count {
        case 1...9:      // 1개도 small로 처리
            return .small
        case 10...49:
            return .medium
        default:
            return .large
        }
    }
}

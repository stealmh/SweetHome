//
//  ImageCountTagView.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit
import SnapKit

class ImageCountTagView: UIView {
    
    // MARK: - UI Components
    private let backgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let countLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption2)
        v.textColor = .white
        v.textAlignment = .center
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        addSubview(backgroundView)
        backgroundView.addSubview(countLabel)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        countLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview().inset(10)
        }
    }
    
    /// - 현재 이미지 인덱스와 전체 개수 설정
    func configure(currentIndex: Int, totalCount: Int) {
        countLabel.text = "\(currentIndex) / \(totalCount)"
    }
}

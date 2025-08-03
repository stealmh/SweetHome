//
//  SHImageCardView.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import SnapKit
import Kingfisher

class SHImageCardView: UIView {
    
    // MARK: - UI Components
    private let backgroundImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()
    
    private let locationTagView = SHLocationTagView()
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.font = SHFont.yeongdeok.setSHFont(.title1)
        v.textColor = SHColor.GrayScale.gray_15
        v.numberOfLines = 2
        return v
    }()
    
    private let introductionLabel: UILabel = {
        let v = UILabel()
        v.font = SHFont.yeongdeok.setSHFont(.caption1)
        v.textColor = SHColor.GrayScale.gray_60
        v.numberOfLines = 0
        return v
    }()
    
    
    // MARK: - Initialization
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
    
    // MARK: - Setup Methods
    private func setupUI() {
        
        addSubviews(
            backgroundImageView,
            locationTagView,
            titleLabel,
            introductionLabel
        )
    }
    
    private func setupConstraints() {
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        locationTagView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(locationTagView.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        introductionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(40)
        }
    }
    
    //TODO: Domain Model 정의 시 함께 작업
    func setData(_ data: Estate) {
        backgroundImageView.setAuthenticatedImage(with: data.thumbnails.first!)
        
        locationTagView.setLabel(location: "서울 반포동")
        titleLabel.text = data.title
        introductionLabel.text = data.introduction
    }
}

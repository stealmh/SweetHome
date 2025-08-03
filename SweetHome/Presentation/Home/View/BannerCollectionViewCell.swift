//
//  BannerCollectionViewCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import SnapKit
import RxSwift

class BannerCollectionViewCell: UICollectionViewCell {
    static let identifier = "BannerCollectionViewCell"
    
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
    
    private var disposeBag = DisposeBag()
    
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    private func setupUI() {
        contentView.addSubviews(
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
        
        introductionLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(40)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.bottom.equalTo(introductionLabel.snp.top).offset(-10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        locationTagView.snp.makeConstraints {
            $0.bottom.equalTo(titleLabel.snp.top).offset(-8)
            $0.leading.equalToSuperview().offset(20)
        }
    }
    
    func configure(with estate: Estate) {
        backgroundImageView.setAuthenticatedImage(with: estate.thumbnails.first!)
        locationTagView.setLabel(location: "서울 반포동")
        titleLabel.text = estate.title
        introductionLabel.text = estate.introduction
    }
}
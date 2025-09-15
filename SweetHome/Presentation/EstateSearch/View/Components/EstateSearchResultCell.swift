//
//  EstateSearchResultCell.swift
//  SweetHome
//
//  Created by 김민호 on 9/14/25.
//

import UIKit
import SnapKit

class EstateSearchResultCell: UICollectionViewCell {
    static let identifier = "EstateSearchResultCell"

    private let thumbnailImageView: UIImageView = {
        let v = UIImageView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 10
        v.contentMode = .scaleToFill
        v.backgroundColor = SHColor.GrayScale.gray_60
        return v
    }()

    private let recommendTagView = SHTagView(text: "추천")

    private let categoryLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.semiBold), size: .caption2)
        v.textColor = SHColor.Brand.deepWood
        return v
    }()

    private let titleLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body3)
        v.textColor = SHColor.GrayScale.gray_100
        v.numberOfLines = 2
        return v
    }()

    private let introductionLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption2)
        v.textColor = SHColor.GrayScale.gray_75
        v.numberOfLines = 1
        return v
    }()

    private let rentPriceLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body3)
        v.textColor = SHColor.GrayScale.gray_90
        return v
    }()

    private let floorsLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption2)
        v.textColor = SHColor.GrayScale.gray_60
        return v
    }()

    private let locationAndSizeLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption1)
        v.textColor = SHColor.GrayScale.gray_60
        return v
    }()

    private let safeEstateTagView = SHTagView(text: "안심매물")

    private let separatorView: UIView = {
        let v = UIView()
        v.backgroundColor = SHColor.GrayScale.gray_60
        return v
    }()

    // 제약 조건 참조 변수들
    private var categoryLabelLeadingConstraint: Constraint?

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
        thumbnailImageView.image = nil
        categoryLabel.text = nil
        titleLabel.text = nil
        introductionLabel.text = nil
        rentPriceLabel.text = nil
        floorsLabel.text = nil
        locationAndSizeLabel.text = nil
        recommendTagView.isHidden = true
        safeEstateTagView.isHidden = true
    }

    private func setupUI() {
        // Simple list cell styling - no container, no border
        backgroundColor = .clear

        contentView.addSubviews(
            thumbnailImageView,
            recommendTagView,
            categoryLabel,
            titleLabel,
            introductionLabel,
            rentPriceLabel,
            floorsLabel,
            locationAndSizeLabel,
            safeEstateTagView,
            separatorView
        )
    }

    private func setupConstraints() {
        thumbnailImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
            $0.width.height.equalTo(100)
        }

        recommendTagView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
//            $0.height.greaterThanOrEqualTo(20)
        }

        categoryLabel.snp.makeConstraints {
            $0.centerY.equalTo(recommendTagView)
            categoryLabelLeadingConstraint = $0.leading.equalTo(recommendTagView.snp.trailing).offset(4).constraint
            $0.trailing.lessThanOrEqualTo(safeEstateTagView.snp.leading).offset(-8)
        }

        safeEstateTagView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.trailing.equalToSuperview().inset(16)
//            $0.height.greaterThanOrEqualTo(20)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(4)
            $0.leading.equalTo(recommendTagView)
            $0.trailing.equalToSuperview().inset(16)
//            $0.height.greaterThanOrEqualTo(22)
        }

        introductionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.leading.equalTo(recommendTagView)
            $0.trailing.equalToSuperview().inset(16)
//            $0.height.greaterThanOrEqualTo(16)
        }

        rentPriceLabel.snp.makeConstraints {
            $0.top.equalTo(introductionLabel.snp.bottom).offset(8)
            $0.leading.equalTo(recommendTagView)
            $0.trailing.equalToSuperview().inset(16)
//            $0.height.greaterThanOrEqualTo(20)
        }

        floorsLabel.snp.makeConstraints {
            $0.top.equalTo(rentPriceLabel.snp.bottom).offset(4)
            $0.leading.equalTo(recommendTagView)
//            $0.height.greaterThanOrEqualTo(16)
        }

        locationAndSizeLabel.snp.makeConstraints {
            $0.centerY.equalTo(floorsLabel)
            $0.leading.equalTo(floorsLabel.snp.trailing).offset(8)
//            $0.height.greaterThanOrEqualTo(16)
        }

        // 썸네일 하단과 맞추기
        let bottomConstraintView = UIView()
        contentView.addSubview(bottomConstraintView)
        bottomConstraintView.snp.makeConstraints {
            $0.top.equalTo(thumbnailImageView.snp.bottom)
            $0.top.greaterThanOrEqualTo(floorsLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(0)
        }

        separatorView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    func configure(with estate: Estate) {
        thumbnailImageView.setAuthenticatedImage(with: estate.thumbnails.first)
        categoryLabel.text = estate.category
        titleLabel.text = estate.title
        introductionLabel.text = estate.introduction
        rentPriceLabel.text = estate.rentDisplayText

        floorsLabel.text = "\(estate.floors)층"
        locationAndSizeLabel.text = "\(estate.area)m²"

        recommendTagView.isHidden = !estate.isRecommended
        safeEstateTagView.isHidden = !estate.isSafeEstate

        // 안심매물 태그 설정
        if estate.isSafeEstate {
            safeEstateTagView.configure(
                text: "안심매물",
                backgroundColor: SHColor.Brand.brightWood,
                textColor: SHColor.GrayScale.gray_0
            )
        }

        // 추천 태그 표시 여부에 따라 categoryLabel 위치 조정
        categoryLabelLeadingConstraint?.deactivate()

        if estate.isRecommended {
            categoryLabel.snp.remakeConstraints {
                $0.centerY.equalTo(recommendTagView)
                categoryLabelLeadingConstraint = $0.leading.equalTo(recommendTagView.snp.trailing).offset(4).constraint
                $0.trailing.lessThanOrEqualTo(safeEstateTagView.snp.leading).offset(-8)
                $0.height.greaterThanOrEqualTo(16)
            }
        } else {
            categoryLabel.snp.remakeConstraints {
                $0.top.equalToSuperview().offset(18)
                categoryLabelLeadingConstraint = $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12).constraint
                $0.trailing.lessThanOrEqualTo(safeEstateTagView.snp.leading).offset(-8)
                $0.height.greaterThanOrEqualTo(16)
            }
        }
    }
}

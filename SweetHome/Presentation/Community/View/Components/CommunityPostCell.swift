//
//  CommunityPostCell.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit
import SnapKit

/// - 커뮤니티 게시글 셀
final class CommunityPostCell: UICollectionViewCell {
    static let identifier = "CommunityPostCell"

    var onLikeTapped: (() -> Void)?

    /// - UI 컴포넌트들
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.medium).setSHFont(.caption1)
        label.textColor = SHColor.Brand.brightWood
        label.backgroundColor = SHColor.Brand.brightCream
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.semiBold).setSHFont(.body1)
        label.textColor = SHColor.GrayScale.gray_15
        label.numberOfLines = 2
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.regular).setSHFont(.body2)
        label.textColor = SHColor.GrayScale.gray_60
        label.numberOfLines = 3
        return label
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = SHColor.GrayScale.gray_90
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.medium).setSHFont(.caption1)
        label.textColor = SHColor.GrayScale.gray_30
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.regular).setSHFont(.caption1)
        label.textColor = SHColor.GrayScale.gray_60
        return label
    }()

    private lazy var likeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = SHColor.Brand.brightWood
        button.titleLabel?.font = SHFont.pretendard(.medium).setSHFont(.caption1)
        button.setTitleColor(SHColor.GrayScale.gray_60, for: .normal)
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()

    private let imageCountLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.medium).setSHFont(.caption1)
        label.textColor = SHColor.GrayScale.gray_60
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// - UI 설정
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubviews(
            categoryLabel,
            titleLabel,
            contentLabel,
            profileImageView,
            nicknameLabel,
            timeLabel,
            likeButton,
            imageCountLabel
        )
    }

    /// - 제약조건 설정
    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        categoryLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(40)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        contentLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        profileImageView.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.width.height.equalTo(32)
            $0.bottom.lessThanOrEqualToSuperview().inset(16)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.centerY.equalTo(profileImageView)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(nicknameLabel.snp.trailing).offset(8)
            $0.centerY.equalTo(profileImageView)
        }

        likeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(profileImageView)
            $0.width.equalTo(60)
            $0.height.equalTo(32)
        }

        imageCountLabel.snp.makeConstraints {
            $0.trailing.equalTo(likeButton.snp.leading).inset(-8)
            $0.centerY.equalTo(profileImageView)
        }
    }

    /// - 데이터 설정
    func configure(with post: CommunityPost) {
        categoryLabel.text = " \(post.category) "
        titleLabel.text = post.title
        contentLabel.text = post.contentPreview
        nicknameLabel.text = post.creator.nick
        timeLabel.text = post.timeAgoText

        /// - 좋아요 버튼 설정
        likeButton.isSelected = post.isLike
        likeButton.setTitle(" \(post.likeCount)", for: .normal)

        /// - 이미지 개수 표시
        if let fileCountText = post.fileCountText {
            imageCountLabel.text = fileCountText
            imageCountLabel.isHidden = false
        } else {
            imageCountLabel.isHidden = true
        }

        /// - 프로필 이미지 설정 (기본 이미지 사용)
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = SHColor.GrayScale.gray_90
    }

    /// - 좋아요 버튼 액션
    @objc private func likeButtonTapped() {
        onLikeTapped?()
    }
}

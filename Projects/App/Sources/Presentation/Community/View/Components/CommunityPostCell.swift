//
//  CommunityPostCell.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit
import SnapKit

final class CommunityPostCell: UICollectionViewCell {
    static let identifier = "CommunityPostCell"

    var onLikeTapped: (() -> Void)?

    /// - UI 컴포넌트들
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = SHColor.GrayScale.gray_60
        button.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.semiBold).setSHFont(.body1)
        label.textColor = .black
        label.numberOfLines = 2
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.regular).setSHFont(.body2)
        label.textColor = SHColor.GrayScale.gray_90
        label.numberOfLines = 3
        return label
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.medium).setSHFont(.body1)
        label.textColor = .black
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.regular).setSHFont(.caption1)
        label.textColor = SHColor.GrayScale.gray_60
        return label
    }()

    private lazy var likeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = SHAsset.Icon.likeEmpty
        config.baseForegroundColor = SHColor.GrayScale.gray_75
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        config.titlePadding = 0

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.configurationUpdateHandler = { [weak self] button in
            var config = button.configuration
            config?.image = button.isSelected ? SHAsset.Icon.likeFill : SHAsset.Icon.likeEmpty
            config?.background.backgroundColor = .clear
            config?.background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in .clear }
            button.configuration = config
        }
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var commentButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        config.image = UIImage(systemName: "message", withConfiguration: imageConfig)
        config.baseForegroundColor = SHColor.GrayScale.gray_75
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        config.titlePadding = 0
        config.background.backgroundColor = .clear
        config.background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in .clear }

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.isUserInteractionEnabled = false
        return button
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = SHColor.GrayScale.gray_75
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        return imageView
    }()

    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = SHColor.GrayScale.gray_75
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.isUserInteractionEnabled = false
        pageControl.isHidden = true
        return pageControl
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = SHColor.GrayScale.gray_30
        return view
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
            profileImageView,
            nicknameLabel,
            timeLabel,
            moreButton,
            titleLabel,
            contentLabel,
            imageView,
            pageControl,
            likeButton,
            commentButton,
            separatorView
        )
    }

    /// - 제약조건 설정
    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        /// - 상단 프로필 영역
        profileImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
            $0.width.height.equalTo(40)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.centerY.equalTo(profileImageView)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(nicknameLabel.snp.trailing).offset(8)
            $0.centerY.equalTo(profileImageView)
        }

        moreButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(profileImageView)
            $0.width.height.equalTo(24)
        }

        /// - 콘텐츠 영역
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        contentLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        /// - 이미지 영역 (1:1.3)
        imageView.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.3)
        }

        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(imageView.snp.bottom).inset(8)
            $0.centerX.equalTo(imageView)
            $0.height.equalTo(10)
        }

        /// - 하단 액션 영역 (동적 제약조건)
        likeButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.width.equalTo(60)
            $0.height.equalTo(32)
        }

        commentButton.snp.makeConstraints {
            $0.leading.equalTo(likeButton.snp.trailing)
            $0.centerY.equalTo(likeButton)
            $0.width.equalTo(60)
            $0.height.equalTo(32)
        }

        /// - 구분선
        separatorView.snp.makeConstraints {
            $0.top.equalTo(likeButton.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
            $0.bottom.equalToSuperview()
        }
    }

    /// - 데이터 설정
    func configure(with post: CommunityPost) {
        titleLabel.text = post.title
        contentLabel.text = post.contentPreview
        nicknameLabel.text = post.creator.nick
        timeLabel.text = post.timeAgoText

        /// - 좋아요 버튼 설정
        likeButton.isSelected = post.isLike
        var config = likeButton.configuration
        config?.title = "\(post.likeCount)"
        config?.attributedTitle = AttributedString("\(post.likeCount)", attributes: AttributeContainer([
            .font: SHFont.pretendard(.semiBold).setSHFont(.body2) ?? UIFont.systemFont(ofSize: 14),
            .foregroundColor: SHColor.GrayScale.gray_75
        ]))
        likeButton.configuration = config

        /// - 댓글 버튼 설정 (임시로 0으로 설정)
        var commentConfig = commentButton.configuration
        commentConfig?.title = "0"
        commentConfig?.attributedTitle = AttributedString("0", attributes: AttributeContainer([
            .font: SHFont.pretendard(.semiBold).setSHFont(.body2) ?? UIFont.systemFont(ofSize: 14),
            .foregroundColor: SHColor.GrayScale.gray_75
        ]))
        commentButton.configuration = commentConfig

        /// - 프로필 이미지 설정 (기본 이미지 사용)
        profileImageView.image = SHAsset.Default.defaultImage
        profileImageView.tintColor = SHColor.GrayScale.gray_90

        /// - 게시물 이미지 설정
        if !post.files.isEmpty {
            imageView.isHidden = false
            pageControl.isHidden = false

            // 임시 이미지 설정 (실제로는 첫 번째 파일을 로드)
            imageView.image = UIImage(named: "food")
            imageView.tintColor = SHColor.GrayScale.gray_60

            // 페이지 컨트롤 설정
            pageControl.numberOfPages = min(post.files.count, 5) // 최대 5장까지 표시
            pageControl.currentPage = 0

            // 이미지가 있을 때 likeButton top 제약조건
            likeButton.snp.remakeConstraints {
                $0.top.equalTo(imageView.snp.bottom).offset(12)
                $0.leading.equalToSuperview().offset(16)
                $0.width.equalTo(60)
                $0.height.equalTo(32)
            }
        } else {
            imageView.isHidden = true
            pageControl.isHidden = true

            // 이미지가 없을 때 likeButton top 제약조건
            likeButton.snp.remakeConstraints {
                $0.top.equalTo(contentLabel.snp.bottom).offset(12)
                $0.leading.equalToSuperview().offset(16)
                $0.width.equalTo(60)
                $0.height.equalTo(32)
            }
        }
    }

    /// - 좋아요 버튼 액션
    @objc private func likeButtonTapped() {
        onLikeTapped?()
    }

    /// - 더보기 버튼 액션
    @objc private func moreButtonTapped() {
        /// - TODO: 더보기 메뉴 표시
        print("More button tapped")
    }
}

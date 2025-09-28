//
//  CommunityDetailViewController.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// - 커뮤니티 게시글 상세 화면
class CommunityDetailViewController: BaseViewController {

    /// - UI 컴포넌트들
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let navigationBar = SHNavigationBar()

    /// - 게시글 내용 영역
    private let postContainerView: UIView = {
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
        label.font = SHFont.pretendard(.regular).setSHFont(.caption1)
        label.textColor = SHColor.Brand.brightWood
        label.backgroundColor = SHColor.Brand.brightCream
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.semiBold).setSHFont(.title1)
        label.textColor = SHColor.GrayScale.gray_15
        label.numberOfLines = 0
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.regular).setSHFont(.body2)
        label.textColor = SHColor.GrayScale.gray_30
        label.numberOfLines = 0
        return label
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = SHColor.GrayScale.gray_90
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.regular).setSHFont(.body2)
        label.textColor = SHColor.GrayScale.gray_15
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
        button.titleLabel?.font = SHFont.pretendard(.medium).setSHFont(.body2)
        button.setTitleColor(SHColor.GrayScale.gray_30, for: .normal)
        return button
    }()

    /// - 댓글 영역
    private let commentsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let commentsLabel: UILabel = {
        let label = UILabel()
        label.text = "댓글"
        label.font = SHFont.pretendard(.semiBold).setSHFont(.title1)
        label.textColor = SHColor.GrayScale.gray_15
        return label
    }()

    private let commentsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()

    /// - 댓글 입력 영역
    private let commentInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 1
        view.layer.borderColor = SHColor.GrayScale.gray_75.cgColor
        return view
    }()

    private let commentTextView: UITextView = {
        let textView = UITextView()
        textView.font = SHFont.pretendard(.regular).setSHFont(.body2)
        textView.textColor = SHColor.GrayScale.gray_100
        textView.backgroundColor = SHColor.GrayScale.gray_0
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("전송", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = SHColor.Brand.brightWood
        button.titleLabel?.font = SHFont.pretendard(.medium).setSHFont(.body2)
        button.layer.cornerRadius = 8
        return button
    }()

    private let viewModel: CommunityDetailViewModel
    private let likeButtonTappedSubject = PublishSubject<Void>()
    private let sendCommentSubject = PublishSubject<Void>()

    init(post: CommunityPost) {
        self.viewModel = CommunityDetailViewModel(post: post)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupKeyboardHandling()
    }

    override func setupUI() {
        view.backgroundColor = SHColor.GrayScale.gray_30
        view.addSubviews(navigationBar, scrollView, commentInputView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(postContainerView, commentsContainerView)

        /// - 게시글 내용 설정
        postContainerView.addSubviews(
            categoryLabel,
            titleLabel,
            contentLabel,
            profileImageView,
            nicknameLabel,
            timeLabel,
            likeButton
        )

        /// - 댓글 영역 설정
        commentsContainerView.addSubviews(commentsLabel, commentsStackView)

        /// - 댓글 입력 영역 설정
        commentInputView.addSubviews(commentTextView, sendButton)
    }

    override func setupConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }

        commentInputView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(80)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(commentInputView.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        postContainerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        /// - 게시글 내용 레이아웃
        categoryLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(20)
            $0.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        contentLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        profileImageView.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.width.height.equalTo(40)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.top.equalTo(profileImageView).offset(2)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.bottom.equalTo(profileImageView).inset(2)
        }

        likeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalTo(profileImageView)
            $0.bottom.equalToSuperview().inset(20)
        }

        /// - 댓글 영역 레이아웃
        commentsContainerView.snp.makeConstraints {
            $0.top.equalTo(postContainerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }

        commentsLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(20)
        }

        commentsStackView.snp.makeConstraints {
            $0.top.equalTo(commentsLabel.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview().inset(20)
        }

        /// - 댓글 입력 영역 레이아웃
        commentTextView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(40)
        }

        sendButton.snp.makeConstraints {
            $0.leading.equalTo(commentTextView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(60)
            $0.height.equalTo(36)
        }
    }

    override func bind() {
        let input = CommunityDetailViewModel.Input(
            viewDidLoad: .just(()),
            likeButtonTapped: likeButtonTappedSubject.asObservable(),
            commentText: commentTextView.rx.text.orEmpty.asObservable(),
            sendComment: sendCommentSubject.asObservable()
        )

        let output = viewModel.transform(input: input)

        /// - 게시글 상세 데이터 바인딩
        output.postDetail
            .drive(onNext: { [weak self] post in
                self?.configurePost(with: post)
                self?.configureComments(with: post.comments)
            })
            .disposed(by: disposeBag)

        /// - 좋아요 상태 바인딩
        output.isLiked
            .drive(likeButton.rx.isSelected)
            .disposed(by: disposeBag)

        output.likeCount
            .map { " \($0)" }
            .drive(likeButton.rx.title(for: .normal))
            .disposed(by: disposeBag)

        /// - 로딩 상태 바인딩
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            })
            .disposed(by: disposeBag)

        /// - 댓글 전송 완료 처리
        output.commentSent
            .drive(onNext: { [weak self] _ in
                self?.commentTextView.text = ""
                /// - TODO: 댓글 목록 새로고침
            })
            .disposed(by: disposeBag)

        /// - 버튼 액션 바인딩
        likeButton.rx.tap
            .bind(to: likeButtonTappedSubject)
            .disposed(by: disposeBag)

        sendButton.rx.tap
            .bind(to: sendCommentSubject)
            .disposed(by: disposeBag)
    }

    /// - 게시글 데이터 설정
    private func configurePost(with post: CommunityPostDetail) {
        categoryLabel.text = " \(post.category) "
        titleLabel.text = post.title
        contentLabel.text = post.content
        nicknameLabel.text = post.creator.nick
        timeLabel.text = post.createdAt.timeAgoText

        /// - 프로필 이미지 설정
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = SHColor.GrayScale.gray_75
    }

    /// - 댓글 설정
    private func configureComments(with comments: [CommunityComment]) {
        /// - 기존 댓글 뷰 제거
        commentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        /// - 새 댓글 뷰 추가
        for comment in comments {
            let commentView = createCommentView(with: comment)
            commentsStackView.addArrangedSubview(commentView)
        }
    }

    /// - 댓글 뷰 생성
    private func createCommentView(with comment: CommunityComment) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = SHColor.GrayScale.gray_30
        containerView.layer.cornerRadius = 8

        let profileImageView = UIImageView()
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = SHColor.GrayScale.gray_75
        profileImageView.layer.cornerRadius = 16
        profileImageView.clipsToBounds = true

        let nicknameLabel = UILabel()
        nicknameLabel.text = comment.creator.nick
        nicknameLabel.font = SHFont.pretendard(.medium).setSHFont(.caption1)
        nicknameLabel.textColor = SHColor.GrayScale.gray_30

        let timeLabel = UILabel()
        timeLabel.text = comment.timeAgoText
        timeLabel.font = SHFont.pretendard(.regular).setSHFont(.caption1)
        timeLabel.textColor = SHColor.GrayScale.gray_60

        let commentLabel = UILabel()
        commentLabel.text = comment.content
        commentLabel.font = SHFont.pretendard(.medium).setSHFont(.body2)
        commentLabel.textColor = SHColor.GrayScale.gray_15
        commentLabel.numberOfLines = 0

        containerView.addSubviews(profileImageView, nicknameLabel, timeLabel, commentLabel)

        profileImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(12)
            $0.width.height.equalTo(32)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.top.equalTo(profileImageView)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(nicknameLabel.snp.trailing).offset(8)
            $0.centerY.equalTo(nicknameLabel)
        }

        commentLabel.snp.makeConstraints {
            $0.top.equalTo(nicknameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.trailing.bottom.equalToSuperview().inset(12)
        }

        return containerView
    }

    /// - 키보드 처리 설정
    private func setupKeyboardHandling() {
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                self?.handleKeyboardShow(notification)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.handleKeyboardHide()
            })
            .disposed(by: disposeBag)
    }

    private func handleKeyboardShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height

        commentInputView.snp.updateConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(keyboardHeight)
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func handleKeyboardHide() {
        commentInputView.snp.updateConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

}

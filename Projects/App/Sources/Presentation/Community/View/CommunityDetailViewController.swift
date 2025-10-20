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

    /// - 게시글 내용 영역 (CommunityPostCell과 동일한 스타일)
    private let postContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = SHColor.GrayScale.gray_60
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.semiBold).setSHFont(.body1)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = SHFont.pretendard(.regular).setSHFont(.body2)
        label.textColor = SHColor.GrayScale.gray_90
        label.numberOfLines = 0
        return label
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 20
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

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = SHColor.GrayScale.gray_30
        return view
    }()

    /// - 댓글 영역 (간단한 리스트)
    private let commentsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()

    /// - 댓글 입력 영역 (ChatDetailInputView 스타일)
    private let commentInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let commentTextView: UITextView = {
        let textView = UITextView()
        textView.font = SHFont.pretendard(.regular).setSHFont(.body2)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 20
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.text = "댓글 달기..."
        textView.textColor = SHColor.GrayScale.gray_60
        return textView
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: config), for: .normal)
        button.tintColor = SHColor.GrayScale.gray_60
        button.backgroundColor = .clear
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
        setupTextViewDelegate()
        navigationBar.configure(title: "")
        setupNavigationBarActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    override func setupUI() {
        view.backgroundColor = .white
        navigationBar.backgroundColor = .clear
        view.addSubviews(navigationBar, scrollView, commentInputView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(postContainerView, separatorView, commentsStackView)

        /// - 게시글 내용 설정 (CommunityPostCell과 동일)
        postContainerView.addSubviews(
            profileImageView,
            nicknameLabel,
            timeLabel,
            moreButton,
            titleLabel,
            contentLabel,
            imageView,
            pageControl,
            likeButton,
            commentButton
        )

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
            $0.leading.trailing.equalToSuperview()
        }

        /// - 게시글 내용 레이아웃 (CommunityPostCell과 동일)
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

        /// - 이미지 영역 (1:1.3 비율)
        imageView.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.3)
        }

        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(imageView.snp.bottom).inset(8)
            $0.centerX.equalTo(imageView)
            $0.height.equalTo(10)
        }

        /// - 하단 액션 영역
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
        }

        /// - 댓글 영역 레이아웃 (간단한 리스트)
        commentsStackView.snp.makeConstraints {
            $0.top.equalTo(separatorView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(20)
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
            $0.width.height.equalTo(36)
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
            .drive(onNext: { [weak self] count in
                var config = self?.likeButton.configuration
                config?.title = "\(count)"
                config?.attributedTitle = AttributedString("\(count)", attributes: AttributeContainer([
                    .font: SHFont.pretendard(.semiBold).setSHFont(.body2) ?? UIFont.systemFont(ofSize: 14),
                    .foregroundColor: SHColor.GrayScale.gray_75
                ]))
                self?.likeButton.configuration = config
            })
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
        titleLabel.text = post.title
        contentLabel.text = post.content
        nicknameLabel.text = post.creator.nick
        timeLabel.text = post.createdAt.timeAgoText

        /// - 네비게이션 타이틀 설정
        navigationBar.configure(title: "\(post.creator.nick)님의 포스트")

        /// - 프로필 이미지 설정
        profileImageView.image = SHAsset.Default.defaultImage
        profileImageView.tintColor = SHColor.GrayScale.gray_90

        /// - 좋아요, 댓글 버튼 설정
        likeButton.isSelected = post.isLike
        var likeConfig = likeButton.configuration
        likeConfig?.title = "\(post.likeCount)"
        likeConfig?.attributedTitle = AttributedString("\(post.likeCount)", attributes: AttributeContainer([
            .font: SHFont.pretendard(.semiBold).setSHFont(.body2) ?? UIFont.systemFont(ofSize: 14),
            .foregroundColor: SHColor.GrayScale.gray_75
        ]))
        likeButton.configuration = likeConfig

        var commentConfig = commentButton.configuration
        commentConfig?.title = "\(post.comments.count)"
        commentConfig?.attributedTitle = AttributedString("\(post.comments.count)", attributes: AttributeContainer([
            .font: SHFont.pretendard(.semiBold).setSHFont(.body2) ?? UIFont.systemFont(ofSize: 14),
            .foregroundColor: SHColor.GrayScale.gray_75
        ]))
        commentButton.configuration = commentConfig

        /// - 게시물 이미지 설정
        if !post.files.isEmpty {
            imageView.isHidden = false
            pageControl.isHidden = false

            // 임시 이미지 설정
            imageView.image = UIImage(named: "food")

            // 페이지 컨트롤 설정
            pageControl.numberOfPages = min(post.files.count, 5)
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

    /// - 댓글 뷰 생성 (간단한 리스트 형식)
    private func createCommentView(with comment: CommunityComment) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .white

        let profileImageView = UIImageView()
        profileImageView.layer.cornerRadius = 14
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill

        let nicknameLabel = UILabel()
        nicknameLabel.text = comment.creator.nick
        nicknameLabel.font = SHFont.pretendard(.medium).setSHFont(.body1)
        nicknameLabel.textColor = .black

        let commentLabel = UILabel()
        commentLabel.text = comment.content
        commentLabel.font = SHFont.pretendard(.regular).setSHFont(.body2)
        commentLabel.textColor = SHColor.GrayScale.gray_90
        commentLabel.numberOfLines = 0

        let timeLabel = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 a h:mm"
        timeLabel.text = formatter.string(from: comment.createdAt)
        timeLabel.font = SHFont.pretendard(.regular).setSHFont(.caption1)
        timeLabel.textColor = SHColor.GrayScale.gray_60

        let replyButton = UIButton()
        replyButton.setTitle("답글달기", for: .normal)
        replyButton.setTitleColor(SHColor.GrayScale.gray_60, for: .normal)
        replyButton.titleLabel?.font = SHFont.pretendard(.medium).setSHFont(.caption1)

        containerView.addSubviews(profileImageView, nicknameLabel, commentLabel, timeLabel, replyButton)

        profileImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.width.height.equalTo(28)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.top.equalTo(profileImageView)
        }

        commentLabel.snp.makeConstraints {
            $0.leading.equalTo(nicknameLabel.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(nicknameLabel)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(nicknameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
        }

        replyButton.snp.makeConstraints {
            $0.leading.equalTo(timeLabel.snp.trailing).offset(12)
            $0.centerY.equalTo(timeLabel)
        }

        containerView.snp.makeConstraints {
            $0.bottom.equalTo(timeLabel.snp.bottom).offset(8)
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

    private func setupTextViewDelegate() {
        commentTextView.delegate = self
        updatePlaceholderVisibility()
    }

    private func updatePlaceholderVisibility() {
        if commentTextView.text.isEmpty || commentTextView.text == "댓글 달기..." {
            commentTextView.text = "댓글 달기..."
            commentTextView.textColor = SHColor.GrayScale.gray_60
        } else {
            commentTextView.textColor = .black
        }
    }

    private func setupNavigationBarActions() {
        navigationBar.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - UITextViewDelegate
extension CommunityDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "댓글 달기..." {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            updatePlaceholderVisibility()
        }
    }
}

//
//  CommunityViewController.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// - 커뮤니티 목록 화면
class CommunityViewController: BaseViewController {

    /// - Layout & DataSource
    private var layoutManager: CommunityCollectionViewLayout!
    private var dataSourceManager: CommunityCollectionViewDataSource!

    /// - UI 컴포넌트들
    private let navigationBar = SHNavigationBar()

    private lazy var collectionView: UICollectionView = {
        layoutManager = CommunityCollectionViewLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layoutManager.createLayout())
        cv.backgroundColor = SHColor.GrayScale.gray_30
        cv.showsVerticalScrollIndicator = false
        cv.register(CommunityPostCell.self, forCellWithReuseIdentifier: CommunityPostCell.identifier)

        dataSourceManager = CommunityCollectionViewDataSource(collectionView: cv, delegate: self)
        return cv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        return refresh
    }()

    private let viewModel = CommunityViewModel()
    private let itemSelectedSubject = PublishSubject<IndexPath>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationBar.configure(title: "커뮤니티")
    }

    override func setupUI() {
        view.backgroundColor = SHColor.GrayScale.gray_30
        view.addSubviews(navigationBar, collectionView)
        collectionView.refreshControl = refreshControl
    }

    override func setupConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    /// - 컬렉션뷰 설정
    private func setupCollectionView() {
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    override func bind() {
        let input = CommunityViewModel.Input(
            viewDidLoad: .just(()),
            refresh: refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            itemSelected: itemSelectedSubject.asObservable()
        )

        let output = viewModel.transform(input: input)

        /// - 게시글 목록 바인딩
        output.posts
            .drive(onNext: { [weak self] posts in
                self?.dataSourceManager.updateSnapshot(with: posts)
            })
            .disposed(by: disposeBag)

        /// - 로딩 상태 바인딩
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                    self?.refreshControl.endRefreshing()
                }
            })
            .disposed(by: disposeBag)

        /// - 에러 처리
        output.error
            .drive(onNext: { [weak self] error in
                self?.hideLoading()
                self?.refreshControl.endRefreshing()
                /// - TODO: 에러 처리 로직 추가
                print("Error occurred: \(error)")
            })
            .disposed(by: disposeBag)

        /// - 게시글 선택 처리
        output.selectedPost
            .drive(onNext: { [weak self] post in
                let detailVC = CommunityDetailViewController(post: post)
                self?.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - CommunityCollectionViewDataSourceDelegate
extension CommunityViewController: CommunityCollectionViewDataSourceDelegate {
    func didSelectPost(at indexPath: IndexPath) {
        itemSelectedSubject.onNext(indexPath)
    }

    func didTapLike(for postId: String) {
        /// - TODO: 좋아요 API 호출
        print("Like tapped for post: \(postId)")
    }
}

//MARK: - UICollectionViewDelegate
extension CommunityViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectPost(at: indexPath)
    }
}
